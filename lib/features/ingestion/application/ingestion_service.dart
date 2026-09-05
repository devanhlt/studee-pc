import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/file_storage/subject_file_store.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/enums/ingestion_job_status.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/source_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';
import 'package:studee_pc/domain/services/source_text_chunker.dart';
import 'package:uuid/uuid.dart';

/// Page text awaiting user review before structuring.
class ReviewedPageText {
  const ReviewedPageText({
    required this.pageNumber,
    required this.text,
    this.imagePath,
    this.ocrConfidence,
  });

  final int pageNumber;
  final String text;
  final String? imagePath;
  final double? ocrConfidence;

  ReviewedPageText copyWith({String? text}) => ReviewedPageText(
        pageNumber: pageNumber,
        text: text ?? this.text,
        imagePath: imagePath,
        ocrConfidence: ocrConfidence,
      );
}

/// Editable draft unit before save.
class StructureDraftUnit {
  StructureDraftUnit({
    required this.id,
    required this.type,
    required this.content,
    this.page,
    this.selected = true,
  });

  final String id;
  KnowledgeUnitType type;
  String content;
  int? page;
  bool selected;
}

/// Editable draft question before save.
class StructureDraftQuestion {
  StructureDraftQuestion({
    required this.id,
    required this.questionType,
    required this.content,
    this.choices = const [],
    this.answerLabel,
    this.answerContent,
    this.explanation,
    this.page,
    this.relatedUnitIds = const [],
    this.selected = true,
  });

  final String id;
  QuestionType questionType;
  String content;
  List<Map<String, String>> choices;
  String? answerLabel;
  String? answerContent;
  String? explanation;
  int? page;
  /// Draft knowledge-unit ids this question depends on.
  List<String> relatedUnitIds;
  bool selected;
}

/// Snapshot of an in-progress ingestion job for the UI.
class IngestionState {
  const IngestionState({
    required this.jobId,
    required this.subjectId,
    required this.status,
    this.sourceId,
    this.sourceType,
    this.currentPage,
    this.totalPages,
    this.errorMessage,
    this.pages = const [],
    this.draftUnits = const [],
    this.draftQuestions = const [],
    this.progressMessage,
  });

  final String jobId;
  final String subjectId;
  final IngestionJobStatus status;
  final String? sourceId;
  final SourceType? sourceType;
  final int? currentPage;
  final int? totalPages;
  final String? errorMessage;
  final List<ReviewedPageText> pages;
  final List<StructureDraftUnit> draftUnits;
  final List<StructureDraftQuestion> draftQuestions;
  final String? progressMessage;

  IngestionState copyWith({
    IngestionJobStatus? status,
    String? sourceId,
    SourceType? sourceType,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
    List<ReviewedPageText>? pages,
    List<StructureDraftUnit>? draftUnits,
    List<StructureDraftQuestion>? draftQuestions,
    String? progressMessage,
    bool clearError = false,
  }) {
    return IngestionState(
      jobId: jobId,
      subjectId: subjectId,
      status: status ?? this.status,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pages: pages ?? this.pages,
      draftUnits: draftUnits ?? this.draftUnits,
      draftQuestions: draftQuestions ?? this.draftQuestions,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }
}

/// Coordinates preserve → OCR/text → review → structure → review → save.
class IngestionService {
  IngestionService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
    required OcrService ocr,
    required SubjectDatabaseManager databaseManager,
    SubjectFileStore? fileStore,
    AppPaths? paths,
    Uuid? uuid,
  })  : _credentials = credentials,
        _deepSeek = deepSeek,
        _ocr = ocr,
        _dbManager = databaseManager,
        _files = fileStore ?? SubjectFileStore(paths: paths),
        _paths = paths ?? AppPaths(),
        _uuid = uuid ?? const Uuid();

  final CredentialsRepository _credentials;
  final DeepSeekClient _deepSeek;
  final OcrService _ocr;
  final SubjectDatabaseManager _dbManager;
  final SubjectFileStore _files;
  final AppPaths _paths;
  final Uuid _uuid;
  final AppLogger _log = AppLogger('IngestionService');

  final StreamController<IngestionState?> _states =
      StreamController<IngestionState?>.broadcast();
  IngestionState? _current;
  bool _cancelled = false;
  String? _activeOcrJobId;

  Stream<IngestionState?> get states => _states.stream;
  IngestionState? get current => _current;

  Future<bool> hasApiKey() => _credentials.hasDeepSeekApiKey();

  Future<Result<IngestionState>> startFromImage({
    required String subjectId,
    required Uint8List bytes,
    required String fileName,
    SourceType type = SourceType.image,
  }) {
    return _startBinary(
      subjectId: subjectId,
      bytes: bytes,
      fileName: fileName,
      type: type,
    );
  }

  Future<Result<IngestionState>> startFromPdf({
    required String subjectId,
    required Uint8List bytes,
    required String fileName,
  }) {
    return _startBinary(
      subjectId: subjectId,
      bytes: bytes,
      fileName: fileName,
      type: SourceType.pdf,
    );
  }

  Future<Result<IngestionState>> startFromPastedText({
    required String subjectId,
    required String text,
    String title = 'Văn bản dán',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Văn bản trống. Hãy dán nội dung trước.',
          code: 'pasted_text_empty',
        ),
      );
    }

    _cancelled = false;
    final jobId = _uuid.v4();
    final sourceId = _uuid.v4();

    try {
      await _dbManager.open(subjectId);
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final bytes = utf8.encode(trimmed);
      final sha = SubjectFileStore.sha256OfBytes(bytes);
      final preserve = await _files.preserveOriginal(
        subjectId: subjectId,
        sourceId: sourceId,
        fileName: 'original.txt',
        bytes: bytes,
      );
      if (preserve is Failure<String>) return Failure(preserve.failure);

      await db.into(db.sources).insert(
            SourcesCompanion.insert(
              id: sourceId,
              type: SourceType.pastedText.wireName,
              title: title,
              originalRelativePath: Value(preserve.valueOrNull),
              contentSha256: sha,
              pageCount: const Value(1),
              processingStatus: IngestionJobStatus.awaitingTextReview.wireName,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final pageId = _uuid.v4();
      await db.into(db.sourcePages).insert(
            SourcePagesCompanion.insert(
              id: pageId,
              sourceId: sourceId,
              pageNumber: 1,
              textLayer: Value(trimmed),
              normalizedText: Value(TextNormalizer.normalize(trimmed)),
              processingStatus: 'ready',
            ),
          );

      await db.into(db.ingestionJobs).insert(
            IngestionJobsCompanion.insert(
              id: jobId,
              sourceId: Value(sourceId),
              status: IngestionJobStatus.awaitingTextReview.wireName,
              currentPage: const Value(1),
              totalPages: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final state = IngestionState(
        jobId: jobId,
        subjectId: subjectId,
        status: IngestionJobStatus.awaitingTextReview,
        sourceId: sourceId,
        sourceType: SourceType.pastedText,
        currentPage: 1,
        totalPages: 1,
        pages: [
          ReviewedPageText(pageNumber: 1, text: trimmed),
        ],
        progressMessage: IngestionJobStatus.awaitingTextReview.labelVi,
      );
      _emit(state);
      return Success(state);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không bắt đầu được nhập kiến thức.',
          code: 'ingestion_start_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<IngestionState>> _startBinary({
    required String subjectId,
    required Uint8List bytes,
    required String fileName,
    required SourceType type,
  }) async {
    _cancelled = false;
    final jobId = _uuid.v4();
    final sourceId = _uuid.v4();
    _activeOcrJobId = jobId;

    try {
      await _dbManager.open(subjectId);
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final sha = SubjectFileStore.sha256OfBytes(bytes);

      _emit(
        IngestionState(
          jobId: jobId,
          subjectId: subjectId,
          status: IngestionJobStatus.preservingSource,
          sourceId: sourceId,
          sourceType: type,
          progressMessage: IngestionJobStatus.preservingSource.labelVi,
        ),
      );

      final preserve = await _files.preserveOriginal(
        subjectId: subjectId,
        sourceId: sourceId,
        fileName: fileName,
        bytes: bytes,
      );
      if (preserve is Failure<String>) return Failure(preserve.failure);

      await db.into(db.sources).insert(
            SourcesCompanion.insert(
              id: sourceId,
              type: type.wireName,
              title: fileName,
              originalRelativePath: Value(preserve.valueOrNull),
              contentSha256: sha,
              processingStatus: IngestionJobStatus.runningOcr.wireName,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.ingestionJobs).insert(
            IngestionJobsCompanion.insert(
              id: jobId,
              sourceId: Value(sourceId),
              status: IngestionJobStatus.runningOcr.wireName,
              createdAt: now,
              updatedAt: now,
            ),
          );

      _emit(
        IngestionState(
          jobId: jobId,
          subjectId: subjectId,
          status: IngestionJobStatus.runningOcr,
          sourceId: sourceId,
          sourceType: type,
          progressMessage: IngestionJobStatus.runningOcr.labelVi,
        ),
      );

      if (_cancelled) return Failure(const CancelledFailure(code: 'cancelled'));

      final sourceFolder = await _paths.sourceFolder(subjectId, sourceId);
      final inputPath = p.join(sourceFolder, fileName);
      final ocrOut = p.join(sourceFolder, 'ocr');

      final pages = <ReviewedPageText>[];
      var failed = false;
      String? failMessage;

      await for (final event in _ocr.process(
        OcrRequest(
          jobId: jobId,
          action: type == SourceType.pdf ? 'parse_document' : 'parse_image',
          inputPath: inputPath,
          outputDirectory: ocrOut,
          languageHints: const ['vi', 'en'],
        ),
      )) {
        if (_cancelled) break;
        switch (event) {
          case OcrProgressEvent(:final page, :final totalPages, :final stage):
            _emit(
              (_current ??
                      IngestionState(
                        jobId: jobId,
                        subjectId: subjectId,
                        status: IngestionJobStatus.runningOcr,
                        sourceId: sourceId,
                        sourceType: type,
                      ))
                  .copyWith(
                status: IngestionJobStatus.runningOcr,
                currentPage: page,
                totalPages: totalPages,
                progressMessage:
                    '${IngestionJobStatus.runningOcr.labelVi} ($stage)',
              ),
            );
          case OcrPageCompletedEvent(:final page, :final resultPath):
            final text = await _readOcrText(ocrOut, resultPath);
            final absImage = p.join(
              sourceFolder,
              'pages',
              'page_${page.toString().padLeft(4, '0')}.png',
            );
            pages.add(
              ReviewedPageText(
                pageNumber: page,
                text: text,
                imagePath: await File(absImage).exists() ? absImage : null,
              ),
            );
            final pageId = _uuid.v4();
            final relativeOcr = p.join(
              'sources',
              AppPaths.sourceFolderName(sourceId),
              'ocr',
              p.basename(resultPath),
            );
            await db.into(db.sourcePages).insert(
                  SourcePagesCompanion.insert(
                    id: pageId,
                    sourceId: sourceId,
                    pageNumber: page,
                    rawOcrRelativePath: Value(relativeOcr),
                    textLayer: Value(text),
                    normalizedText: Value(TextNormalizer.normalize(text)),
                    ocrEngine: const Value('paddleocr-vl'),
                    ocrModelVersion: const Value('1.6'),
                    processingStatus: 'ocr_done',
                  ),
                );
          case OcrWarningEvent(:final message, :final code):
            _log.warning('OCR warning code=$code');
            failMessage ??= message;
          case OcrCompletedEvent():
            break;
          case OcrFailedEvent(:final code, :final message):
            failed = true;
            failMessage = message ?? code;
        }
      }

      if (_cancelled) {
        await _updateJob(db, jobId, IngestionJobStatus.cancelled);
        final cancelled = (_current ??
                IngestionState(
                  jobId: jobId,
                  subjectId: subjectId,
                  status: IngestionJobStatus.cancelled,
                ))
            .copyWith(status: IngestionJobStatus.cancelled);
        _emit(cancelled);
        return Failure(const CancelledFailure(code: 'cancelled'));
      }

      if (failed && pages.isEmpty) {
        await _updateJob(
          db,
          jobId,
          IngestionJobStatus.failed,
          error: failMessage,
        );
        final failState = IngestionState(
          jobId: jobId,
          subjectId: subjectId,
          status: IngestionJobStatus.failed,
          sourceId: sourceId,
          sourceType: type,
          errorMessage: failMessage ?? 'OCR thất bại.',
          progressMessage: IngestionJobStatus.failed.labelVi,
        );
        _emit(failState);
        return Failure(
          OcrFailure(
            userMessage: failMessage ?? 'Nhận dạng văn bản thất bại.',
            code: 'ocr_failed',
          ),
        );
      }

      // Fallback when worker is missing: treat binary as single page stub text.
      if (pages.isEmpty) {
        pages.add(
          ReviewedPageText(
            pageNumber: 1,
            text: type == SourceType.pdf
                ? '[PDF] Chưa có lớp văn bản. Chạy OCR hoặc dán văn bản thủ công.'
                : '[Ảnh] Chưa nhận dạng được. Hãy chỉnh sửa văn bản thủ công.',
          ),
        );
        await db.into(db.sourcePages).insert(
              SourcePagesCompanion.insert(
                id: _uuid.v4(),
                sourceId: sourceId,
                pageNumber: 1,
                textLayer: Value(pages.first.text),
                normalizedText:
                    Value(TextNormalizer.normalize(pages.first.text)),
                processingStatus: 'awaiting_review',
              ),
            );
      }

      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      await _updateJob(db, jobId, IngestionJobStatus.awaitingTextReview);
      await (db.update(db.sources)..where((t) => t.id.equals(sourceId))).write(
        SourcesCompanion(
          pageCount: Value(pages.length),
          processingStatus:
              Value(IngestionJobStatus.awaitingTextReview.wireName),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      final state = IngestionState(
        jobId: jobId,
        subjectId: subjectId,
        status: IngestionJobStatus.awaitingTextReview,
        sourceId: sourceId,
        sourceType: type,
        currentPage: pages.length,
        totalPages: pages.length,
        pages: pages,
        progressMessage: IngestionJobStatus.awaitingTextReview.labelVi,
      );
      _emit(state);
      return Success(state);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không bắt đầu được nhập kiến thức.',
          code: 'ingestion_start_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Applies user-edited page texts, then calls DeepSeek structuring.
  Future<Result<IngestionState>> submitTextReview(
    List<ReviewedPageText> reviewedPages,
  ) async {
    final current = _current;
    if (current == null || current.sourceId == null) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không có phiên nhập đang mở.',
          code: 'no_ingestion_job',
        ),
      );
    }
    if (_cancelled) {
      return const Failure(CancelledFailure(code: 'cancelled'));
    }

    final gate = await _requireApiKey();
    if (gate != null) return Failure(gate);

    try {
      final db = _dbManager.requireActive();
      _emit(
        current.copyWith(
          status: IngestionJobStatus.structuring,
          pages: reviewedPages,
          progressMessage: IngestionJobStatus.structuring.labelVi,
          clearError: true,
        ),
      );
      await _updateJob(db, current.jobId, IngestionJobStatus.structuring);

      for (final page in reviewedPages) {
        await (db.update(db.sourcePages)
              ..where(
                (t) =>
                    t.sourceId.equals(current.sourceId!) &
                    t.pageNumber.equals(page.pageNumber),
              ))
            .write(
          SourcePagesCompanion(
            textLayer: Value(page.text),
            normalizedText: Value(TextNormalizer.normalize(page.text)),
            processingStatus: const Value('reviewed'),
          ),
        );
      }

      final pageTexts = reviewedPages
          .map(
            (p) => StructurePageText(
              pageNumber: p.pageNumber,
              text: p.text,
            ),
          )
          .toList();

      // Large exams (40+ Q&A) are split so each DeepSeek call stays bounded.
      const chunker = SourceTextChunker();
      final chunks = chunker.chunkPages(pageTexts);
      _log.info(
        'Structuring source=${current.sourceId} pages=${pageTexts.length} '
        'chunks=${chunks.length} '
        'detectedQ=${chunks.fold<int>(0, (s, c) => s + c.questionCount)} '
        'chars=${pageTexts.fold<int>(0, (s, p) => s + p.text.length)}',
      );

      final batchResponses = <StructureSourceResponse>[];
      for (var i = 0; i < chunks.length; i++) {
        if (_cancelled) {
          return const Failure(CancelledFailure(code: 'cancelled'));
        }
        final chunk = chunks[i];
        _emit(
          current.copyWith(
            status: IngestionJobStatus.structuring,
            pages: reviewedPages,
            currentPage: i + 1,
            totalPages: chunks.length,
            progressMessage: chunks.length == 1
                ? IngestionJobStatus.structuring.labelVi
                : 'Đang cấu trúc hóa phần ${i + 1}/${chunks.length}'
                    '${chunk.questionCount > 0 ? ' (~${chunk.questionCount} câu)' : ''}'
                    ' (DeepSeek)…',
            clearError: true,
          ),
        );

        final part = await _deepSeek.structureSource(
          StructureSourceRequest(
            sourceId: current.sourceId!,
            pageTexts: chunk.pageTexts,
          ),
        );
        batchResponses.add(part);
        _log.info(
          'Structure chunk ${i + 1}/${chunks.length}: '
          'units=${part.knowledgeUnits.length} questions=${part.questions.length}',
        );
      }

      if (_cancelled) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }

      final response = StructureBatchMerger.merge(batchResponses);

      final units = <StructureDraftUnit>[];
      for (final m in response.knowledgeUnits) {
        final content = (m['content'] as String? ?? '').trim();
        if (content.isEmpty) continue;
        units.add(
          StructureDraftUnit(
            id: _uuid.v4(),
            type: KnowledgeUnitType.fromWire(
              m['type'] as String? ?? 'note',
            ),
            content: content,
            page: (m['page'] as num?)?.toInt(),
          ),
        );
      }

      final questions = <StructureDraftQuestion>[];
      for (final m in response.questions) {
        final content = (m['content'] as String? ?? '').trim();
        if (content.isEmpty) continue;
        final choicesRaw = m['choices'] as List<dynamic>? ?? const [];
        final choices = choicesRaw
            .whereType<Map>()
            .map(
              (c) => {
                'label': (c['label'] ?? '').toString(),
                'content': (c['content'] ?? '').toString(),
              },
            )
            .toList();
        final answerLabel = (m['answer_label'] as String?)?.trim();
        var answerContent = (m['answer_content'] as String?)?.trim();
        answerContent = _enrichAnswerContent(
          answerLabel: answerLabel,
          answerContent: answerContent,
          choices: choices,
        );
        final explanation = (m['explanation'] as String?)?.trim();

        final relatedIds = <String>[];
        final relatedIdx =
            m['related_knowledge_indices'] as List<dynamic>? ?? const [];
        for (final rawIdx in relatedIdx) {
          final idx = (rawIdx as num?)?.toInt();
          if (idx == null || idx < 0 || idx >= units.length) continue;
          relatedIds.add(units[idx].id);
        }

        // Ensure detailed answer / solution exist as knowledge units for retrieval.
        if (answerContent != null && answerContent.isNotEmpty) {
          final answerUnit = StructureDraftUnit(
            id: _uuid.v4(),
            type: KnowledgeUnitType.answerKey,
            content: answerLabel != null && answerLabel.isNotEmpty
                ? 'Đáp án $answerLabel: $answerContent'
                : answerContent,
            page: (m['page'] as num?)?.toInt(),
          );
          units.add(answerUnit);
          relatedIds.add(answerUnit.id);
        }
        if (explanation != null && explanation.isNotEmpty) {
          final solutionUnit = StructureDraftUnit(
            id: _uuid.v4(),
            type: KnowledgeUnitType.solution,
            content: explanation,
            page: (m['page'] as num?)?.toInt(),
          );
          units.add(solutionUnit);
          relatedIds.add(solutionUnit.id);
        }

        questions.add(
          StructureDraftQuestion(
            id: _uuid.v4(),
            questionType: QuestionType.fromWire(
              m['question_type'] as String? ?? 'text_response',
            ),
            content: content,
            choices: choices,
            answerLabel: answerLabel,
            answerContent: answerContent,
            explanation: explanation,
            page: (m['page'] as num?)?.toInt(),
            relatedUnitIds: relatedIds,
          ),
        );
      }

      // Persist model relations by converting unit indices → draft ids after
      // answer/solution units were appended (index-based links only for original).
      final draftJson = jsonEncode({
        'knowledge_units': response.knowledgeUnits,
        'questions': response.questions,
        'relations': response.relations,
        'prompt_version': response.promptVersion,
      });
      await (db.update(db.ingestionJobs)
            ..where((t) => t.id.equals(current.jobId)))
          .write(
        IngestionJobsCompanion(
          status: Value(IngestionJobStatus.awaitingStructureReview.wireName),
          draftJson: Value(draftJson),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      final state = current.copyWith(
        status: IngestionJobStatus.awaitingStructureReview,
        pages: reviewedPages,
        draftUnits: units,
        draftQuestions: questions,
        progressMessage: IngestionJobStatus.awaitingStructureReview.labelVi,
        clearError: true,
      );
      _emit(state);
      return Success(state);
    } on AppFailure catch (f) {
      final failed = _current?.copyWith(
        status: IngestionJobStatus.failed,
        errorMessage: f.userMessage,
        progressMessage: IngestionJobStatus.failed.labelVi,
      );
      if (failed != null) _emit(failed);
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Cấu trúc hóa nguồn thất bại.',
          code: 'structure_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Saves selected draft units/questions transactionally as `unreviewed`.
  Future<Result<IngestionState>> submitStructureReview({
    required List<StructureDraftUnit> units,
    required List<StructureDraftQuestion> questions,
  }) async {
    final current = _current;
    if (current == null || current.sourceId == null) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không có phiên nhập đang mở.',
          code: 'no_ingestion_job',
        ),
      );
    }

    try {
      final db = _dbManager.requireActive();
      _emit(
        current.copyWith(
          status: IngestionJobStatus.saving,
          draftUnits: units,
          draftQuestions: questions,
          progressMessage: IngestionJobStatus.saving.labelVi,
          clearError: true,
        ),
      );
      await _updateJob(db, current.jobId, IngestionJobStatus.saving);

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final selectedUnits = units.where((u) => u.selected).toList();
      final selectedQuestions = questions.where((q) => q.selected).toList();

      await db.transaction(() async {
        final savedUnitIds = <String>{};

        for (final unit in selectedUnits) {
          await db.into(db.knowledgeUnits).insert(
                KnowledgeUnitsCompanion.insert(
                  id: unit.id,
                  sourceId: current.sourceId!,
                  type: unit.type.wireName,
                  content: unit.content,
                  normalizedContent: TextNormalizer.normalize(unit.content),
                  verificationStatus: VerificationStatus.reviewed.wireName,
                  contentHash: Fingerprints.contentHash(unit.content),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          savedUnitIds.add(unit.id);
        }

        // Also keep related units referenced by selected questions even if the
        // user somehow deselected them (answer/solution auto-units).
        for (final q in selectedQuestions) {
          for (final relatedId in q.relatedUnitIds) {
            if (savedUnitIds.contains(relatedId)) continue;
            final unit = units.where((u) => u.id == relatedId).firstOrNull;
            if (unit == null) continue;
            await db.into(db.knowledgeUnits).insert(
                  KnowledgeUnitsCompanion.insert(
                    id: unit.id,
                    sourceId: current.sourceId!,
                    type: unit.type.wireName,
                    content: unit.content,
                    normalizedContent: TextNormalizer.normalize(unit.content),
                    verificationStatus: VerificationStatus.reviewed.wireName,
                    contentHash: Fingerprints.contentHash(unit.content),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
            savedUnitIds.add(unit.id);
          }
        }

        for (final q in selectedQuestions) {
          final detailedAnswer = _enrichAnswerContent(
            answerLabel: q.answerLabel,
            answerContent: q.answerContent,
            choices: q.choices,
          );
          q.answerContent = detailedAnswer;

          // Prefer a related theory/definition/formula unit as parent; else
          // create a question-stem unit so retrieval has searchable content.
          String knowledgeUnitId;
          final relatedExisting = q.relatedUnitIds
              .where(savedUnitIds.contains)
              .toList();
          StructureDraftUnit? preferredParent;
          for (final u in units) {
            if (!relatedExisting.contains(u.id)) continue;
            if (u.type == KnowledgeUnitType.theory ||
                u.type == KnowledgeUnitType.definition ||
                u.type == KnowledgeUnitType.formula ||
                u.type == KnowledgeUnitType.theorem ||
                u.type == KnowledgeUnitType.example) {
              preferredParent = u;
              break;
            }
          }
          if (preferredParent != null) {
            knowledgeUnitId = preferredParent.id;
          } else if (relatedExisting.isNotEmpty) {
            knowledgeUnitId = relatedExisting.first;
          } else {
            knowledgeUnitId = _uuid.v4();
            await db.into(db.knowledgeUnits).insert(
                  KnowledgeUnitsCompanion.insert(
                    id: knowledgeUnitId,
                    sourceId: current.sourceId!,
                    type: KnowledgeUnitType.question.wireName,
                    content: q.content,
                    normalizedContent: TextNormalizer.normalize(q.content),
                    verificationStatus: VerificationStatus.reviewed.wireName,
                    contentHash: Fingerprints.contentHash(q.content),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
            savedUnitIds.add(knowledgeUnitId);
          }

          final qId = q.id;
          final choiceContents = q.choices.map((c) => c['content'] ?? '');
          await db.into(db.questions).insert(
                QuestionsCompanion.insert(
                  id: qId,
                  knowledgeUnitId: knowledgeUnitId,
                  questionType: q.questionType.wireName,
                  content: q.content,
                  normalizedContent: TextNormalizer.normalizeQuestionText(
                    q.content,
                  ),
                  questionFingerprint: Fingerprints.questionFingerprint(
                    questionText: q.content,
                    choiceContents: choiceContents,
                  ),
                  answerLabel: Value(q.answerLabel),
                  answerContent: Value(detailedAnswer),
                  explanation: Value(q.explanation),
                  verificationStatus: VerificationStatus.reviewed.wireName,
                  createdAt: now,
                  updatedAt: now,
                ),
              );

          var order = 0;
          for (final choice in q.choices) {
            final label = choice['label'] ?? '';
            final content = choice['content'] ?? '';
            if (label.isEmpty && content.isEmpty) continue;
            await db.into(db.questionChoices).insert(
                  QuestionChoicesCompanion.insert(
                    id: _uuid.v4(),
                    questionId: qId,
                    label: label.isEmpty ? '${order + 1}' : label,
                    content: content,
                    normalizedContent:
                        TextNormalizer.normalizeChoiceContent(content),
                    sortOrder: order,
                  ),
                );
            order++;
          }

          // Link question parent ↔ related knowledge for later retrieval context.
          for (final relatedId in relatedExisting) {
            if (relatedId == knowledgeUnitId) continue;
            await db.into(db.knowledgeRelations).insert(
                  KnowledgeRelationsCompanion.insert(
                    id: _uuid.v4(),
                    fromUnitId: knowledgeUnitId,
                    toUnitId: relatedId,
                    relationType: 'related_to',
                    createdAt: now,
                  ),
                );
          }
        }

        await (db.update(db.sources)
              ..where((t) => t.id.equals(current.sourceId!)))
            .write(
          SourcesCompanion(
            processingStatus: Value(IngestionJobStatus.completed.wireName),
            updatedAt: Value(now),
          ),
        );
      });

      await _updateJob(db, current.jobId, IngestionJobStatus.completed);
      final state = current.copyWith(
        status: IngestionJobStatus.completed,
        draftUnits: units,
        draftQuestions: questions,
        progressMessage: IngestionJobStatus.completed.labelVi,
        clearError: true,
      );
      _emit(state);
      _log.info('Ingestion completed job=${current.jobId}');
      return Success(state);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không lưu được kiến thức đã duyệt.',
          code: 'ingestion_save_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    final ocrJob = _activeOcrJobId;
    if (ocrJob != null) {
      await _ocr.cancel(ocrJob);
    }
    final current = _current;
    if (current != null && !current.status.isTerminal) {
      try {
        final db = _dbManager.activeDatabase;
        if (db != null) {
          await _updateJob(db, current.jobId, IngestionJobStatus.cancelled);
        }
      } on Object {
        // Best-effort.
      }
      _emit(current.copyWith(status: IngestionJobStatus.cancelled));
    }
  }

  /// Prefer detailed answer text over a bare A/B/C label.
  static String? _enrichAnswerContent({
    required String? answerLabel,
    required String? answerContent,
    required List<Map<String, String>> choices,
  }) {
    final label = answerLabel?.trim();
    final content = answerContent?.trim();

    bool isBareLabel(String value) {
      final v = value.trim();
      if (v.isEmpty) return true;
      if (label != null &&
          TextNormalizer.normalize(v) == TextNormalizer.normalize(label)) {
        return true;
      }
      return RegExp(r'^[A-Da-d]$').hasMatch(v);
    }

    if (content != null && content.isNotEmpty && !isBareLabel(content)) {
      return content;
    }

    if (label != null && label.isNotEmpty) {
      for (final choice in choices) {
        final choiceLabel = (choice['label'] ?? '').trim();
        final choiceContent = (choice['content'] ?? '').trim();
        if (choiceLabel.toUpperCase() != label.toUpperCase()) continue;
        if (choiceContent.isEmpty) continue;
        return choiceContent;
      }
    }

    return content?.isNotEmpty == true ? content : null;
  }

  void reset() {
    _cancelled = false;
    _activeOcrJobId = null;
    _current = null;
    if (!_states.isClosed) _states.add(null);
  }

  /// Clears a finished/cancelled job (or a job for another subject) so a new
  /// import can start. Leaves in-progress jobs alone.
  void prepareForSubject(String subjectId) {
    final current = _current;
    if (current == null) return;
    if (current.subjectId != subjectId || current.status.isTerminal) {
      reset();
    }
  }

  Future<void> dispose() async {
    await _states.close();
  }

  Future<AppFailure?> _requireApiKey() async {
    final has = await _credentials.hasDeepSeekApiKey();
    if (!has) {
      return const MissingApiKeyFailure(
        userMessage: 'Nhập khóa API DeepSeek',
      );
    }
    return null;
  }

  void _emit(IngestionState state) {
    _current = state;
    if (!_states.isClosed) _states.add(state);
  }

  Future<void> _updateJob(
    SubjectDatabase db,
    String jobId,
    IngestionJobStatus status, {
    String? error,
  }) async {
    await (db.update(db.ingestionJobs)..where((t) => t.id.equals(jobId)))
        .write(
      IngestionJobsCompanion(
        status: Value(status.wireName),
        errorMessage: Value(error),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  Future<String> _readOcrText(String ocrOut, String resultPath) async {
    final candidates = [
      resultPath,
      p.join(ocrOut, resultPath),
      p.join(ocrOut, p.basename(resultPath)),
    ];
    for (final path in candidates) {
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final text = decoded['text'] ??
              decoded['normalized_text'] ??
              decoded['content'];
          if (text is String) return text;
          final blocks = decoded['blocks'] as List<dynamic>?;
          if (blocks != null) {
            return blocks
                .map((b) => (b is Map ? b['text'] : null)?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .join('\n');
          }
        }
        return raw;
      } on Object {
        continue;
      }
    }
    return '';
  }
}
