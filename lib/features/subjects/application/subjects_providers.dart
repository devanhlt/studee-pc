import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/data/backend/quota_tokens.dart';
import 'package:studee_pc/domain/entities/create_subject_input.dart';
import 'package:studee_pc/domain/entities/knowledge_unit.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/entities/source.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/source_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/features/subjects/application/study_notes_builder.dart';

final subjectsListProvider =
    FutureProvider.autoDispose<List<Subject>>((ref) async {
  final repo = ref.watch(subjectRepositoryProvider);
  return repo.listSubjects();
});

final subjectByIdProvider =
    FutureProvider.autoDispose.family<Subject?, String>((ref, id) async {
  final list = await ref.watch(subjectsListProvider.future);
  try {
    return list.firstWhere((s) => s.id == id);
  } on StateError {
    return null;
  }
});

class SubjectContentQueries {
  SubjectContentQueries(this._ref);

  final Ref _ref;

  Future<List<KnowledgeUnit>> listKnowledge(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.knowledgeUnits)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => KnowledgeUnit(
            id: r.id,
            sourceId: r.sourceId,
            sourcePageId: r.sourcePageId,
            type: KnowledgeUnitType.fromWire(r.type),
            content: r.content,
            normalizedContent: r.normalizedContent,
            bboxJson: r.bboxJson,
            verificationStatus:
                VerificationStatus.fromWire(r.verificationStatus),
            sourcePriority: r.sourcePriority,
            contentHash: r.contentHash,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        )
        .toList();
  }

  Future<List<Question>> listQuestions(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.questions)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => Question(
            id: r.id,
            knowledgeUnitId: r.knowledgeUnitId,
            questionNumber: r.questionNumber,
            questionType: QuestionType.fromWire(r.questionType),
            content: r.content,
            normalizedContent: r.normalizedContent,
            questionFingerprint: r.questionFingerprint,
            answerLabel: r.answerLabel,
            answerContent: r.answerContent,
            explanation: r.explanation,
            verificationStatus:
                VerificationStatus.fromWire(r.verificationStatus),
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
            practiceCount: r.practiceCount,
          ),
        )
        .toList();
  }

  /// Questions with [Question.choices] loaded (for study-notes export).
  Future<List<Question>> listQuestionsWithChoices(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.questions)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final out = <Question>[];
    for (final r in rows) {
      final choiceRows = await (db.select(db.questionChoices)
            ..where((c) => c.questionId.equals(r.id))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();
      final choices = choiceRows
          .map(
            (c) => QuestionChoice(
              id: c.id,
              questionId: c.questionId,
              label: c.label,
              content: c.content,
              normalizedContent: c.normalizedContent,
              sortOrder: c.sortOrder,
            ),
          )
          .toList();
      out.add(
        Question(
          id: r.id,
          knowledgeUnitId: r.knowledgeUnitId,
          questionNumber: r.questionNumber,
          questionType: QuestionType.fromWire(r.questionType),
          content: r.content,
          normalizedContent: r.normalizedContent,
          questionFingerprint: r.questionFingerprint,
          answerLabel: r.answerLabel,
          answerContent: r.answerContent,
          explanation: r.explanation,
          verificationStatus:
              VerificationStatus.fromWire(r.verificationStatus),
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
          updatedAt:
              DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          choices: choices,
          practiceCount: r.practiceCount,
        ),
      );
    }
    return out;
  }

  /// Bump practice count for a stored question (Giải / Luyện / Ôn tập).
  Future<void> incrementPracticeCount({
    required String subjectId,
    required String questionId,
  }) async {
    if (questionId.trim().isEmpty) return;
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.customUpdate(
      'UPDATE questions SET practice_count = practice_count + 1, updated_at = ? WHERE id = ?',
      variables: [Variable.withInt(now), Variable.withString(questionId)],
      updates: {db.questions},
    );
  }

  /// Bump practice count for questions matching [questionFingerprint].
  Future<int> incrementPracticeCountByFingerprint({
    required String subjectId,
    required String questionFingerprint,
  }) async {
    final fp = questionFingerprint.trim();
    if (fp.isEmpty) return 0;
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return db.customUpdate(
      'UPDATE questions SET practice_count = practice_count + 1, updated_at = ? '
      'WHERE question_fingerprint = ?',
      variables: [Variable.withInt(now), Variable.withString(fp)],
      updates: {db.questions},
    );
  }

  /// Persist LaTeX-normalized stem / choices / answer for display.
  Future<void> updateQuestionMath({
    required String subjectId,
    required String questionId,
    required String content,
    List<({String id, String content})> choices = const [],
    String? answerContent,
  }) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final choiceBodies = choices.map((c) => c.content);
    await (db.update(db.questions)..where((q) => q.id.equals(questionId)))
        .write(
      QuestionsCompanion(
        content: Value(content),
        normalizedContent: Value(TextNormalizer.normalizeQuestionText(content)),
        questionFingerprint: Value(
          Fingerprints.questionFingerprint(
            questionText: content,
            choiceContents: choiceBodies,
          ),
        ),
        answerContent: answerContent == null
            ? const Value.absent()
            : Value(answerContent),
        updatedAt: Value(now),
      ),
    );
    for (final c in choices) {
      if (c.id.isEmpty) continue;
      await (db.update(db.questionChoices)..where((t) => t.id.equals(c.id)))
          .write(
        QuestionChoicesCompanion(
          content: Value(c.content),
          normalizedContent: Value(
            TextNormalizer.normalizeChoiceContent(c.content),
          ),
        ),
      );
    }
  }

  Future<List<Source>> listSources(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.sources)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => Source(
            id: r.id,
            type: SourceType.fromWire(r.type),
            title: r.title,
            originalRelativePath: r.originalRelativePath,
            contentSha256: r.contentSha256,
            pageCount: r.pageCount,
            processingStatus: r.processingStatus,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        )
        .toList();
  }

  Future<List<SolveHistoryItem>> listSolveHistory(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final sessions = await (db.select(db.solveSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final items = <SolveHistoryItem>[];
    for (final session in sessions) {
      final result = await (db.select(db.solveResults)
            ..where((t) => t.sessionId.equals(session.id))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      items.add(
        SolveHistoryItem(
          sessionId: session.id,
          inputType: session.inputType,
          status: session.status,
          preview: session.rawInputText,
          answerLabel: result?.finalAnswerLabel,
          answerContent: result?.finalAnswerContent ?? result?.shortAnswer,
          confidence: result?.confidenceLevel,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            session.createdAt,
            isUtc: true,
          ),
        ),
      );
    }
    return items;
  }

  Future<SolveHistoryDetail?> getSolveHistoryDetail({
    required String subjectId,
    required String sessionId,
  }) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final session = await (db.select(db.solveSessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
    if (session == null) return null;

    final result = await (db.select(db.solveResults)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    var references = <SolveHistoryReference>[];
    if (result != null) {
      final refs = await (db.select(db.resultReferences)
            ..where((t) => t.resultId.equals(result.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      references = refs
          .map(
            (r) => SolveHistoryReference(
              localId: r.localId,
              sourceTitle: r.sourceTitle,
              page: r.page,
            ),
          )
          .toList();
    }

    Map<String, dynamic>? parsedQuestion;
    final rawParsed = session.parsedQuestionJson;
    if (rawParsed != null && rawParsed.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawParsed);
        if (decoded is Map) {
          parsedQuestion = Map<String, dynamic>.from(decoded);
        }
      } on Object catch (_) {}
    }

    List<String> warnings = const [];
    if (result?.warningsJson != null) {
      try {
        final decoded = jsonDecode(result!.warningsJson!);
        if (decoded is List) {
          warnings = decoded.map((e) => '$e').where((e) => e.isNotEmpty).toList();
        }
      } on Object catch (_) {}
    }

    return SolveHistoryDetail(
      sessionId: session.id,
      inputType: session.inputType,
      status: session.status,
      rawInputText: session.rawInputText,
      parsedQuestion: parsedQuestion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        session.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        session.updatedAt,
        isUtc: true,
      ),
      resultId: result?.id,
      questionType: result?.questionType,
      answerLabel: result?.finalAnswerLabel,
      answerContent: result?.finalAnswerContent,
      shortAnswer: result?.shortAnswer,
      explanationMarkdown: result?.explanationMarkdown,
      confidence: result?.confidenceLevel,
      modelKnowledgeUsed: (result?.modelKnowledgeUsed ?? 0) == 1,
      missingInformation: (result?.missingInformation ?? 0) == 1,
      warnings: warnings,
      references: references,
    );
  }

  /// Deletes a solve session; results / refs / feedback cascade via FK.
  Future<void> deleteSolveSession({
    required String subjectId,
    required String sessionId,
  }) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    await (db.delete(db.solveSessions)..where((t) => t.id.equals(sessionId)))
        .go();
  }
}

class SolveHistoryItem {
  const SolveHistoryItem({
    required this.sessionId,
    required this.inputType,
    required this.status,
    this.preview,
    this.answerLabel,
    this.answerContent,
    this.confidence,
    required this.createdAt,
  });

  final String sessionId;
  final String inputType;
  final String status;
  final String? preview;
  final String? answerLabel;
  final String? answerContent;
  final String? confidence;
  final DateTime createdAt;
}

class SolveHistoryReference {
  const SolveHistoryReference({
    required this.localId,
    this.sourceTitle,
    this.page,
  });

  final String localId;
  final String? sourceTitle;
  final int? page;
}

class SolveHistoryDetail {
  const SolveHistoryDetail({
    required this.sessionId,
    required this.inputType,
    required this.status,
    this.rawInputText,
    this.parsedQuestion,
    required this.createdAt,
    required this.updatedAt,
    this.resultId,
    this.questionType,
    this.answerLabel,
    this.answerContent,
    this.shortAnswer,
    this.explanationMarkdown,
    this.confidence,
    this.modelKnowledgeUsed = false,
    this.missingInformation = false,
    this.warnings = const [],
    this.references = const [],
  });

  final String sessionId;
  final String inputType;
  final String status;
  final String? rawInputText;
  final Map<String, dynamic>? parsedQuestion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resultId;
  final String? questionType;
  final String? answerLabel;
  final String? answerContent;
  final String? shortAnswer;
  final String? explanationMarkdown;
  final String? confidence;
  final bool modelKnowledgeUsed;
  final bool missingInformation;
  final List<String> warnings;
  final List<SolveHistoryReference> references;
}

final subjectContentProvider = Provider<SubjectContentQueries>((ref) {
  return SubjectContentQueries(ref);
});

final subjectKnowledgeProvider =
    FutureProvider.autoDispose.family<List<KnowledgeUnit>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listKnowledge(subjectId),
);

final subjectQuestionsProvider =
    FutureProvider.autoDispose.family<List<Question>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listQuestions(subjectId),
);

final subjectSourcesProvider =
    FutureProvider.autoDispose.family<List<Source>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listSources(subjectId),
);

final subjectHistoryProvider =
    FutureProvider.autoDispose.family<List<SolveHistoryItem>, String>(
  (ref, subjectId) =>
      ref.watch(subjectContentProvider).listSolveHistory(subjectId),
);

final subjectHistoryDetailProvider = FutureProvider.autoDispose
    .family<SolveHistoryDetail?, ({String subjectId, String sessionId})>(
  (ref, args) => ref.watch(subjectContentProvider).getSolveHistoryDetail(
        subjectId: args.subjectId,
        sessionId: args.sessionId,
      ),
);

class SubjectsActions {
  SubjectsActions(this._ref);

  final Ref _ref;

  Future<Subject> create(String name, {String? icon, int? color}) {
    return _ref.read(subjectRepositoryProvider).createSubject(
          CreateSubjectInput(name: name, icon: icon, color: color),
        );
  }

  Future<void> rename(String id, String name) {
    return _ref.read(subjectRepositoryProvider).renameSubject(id, name);
  }

  Future<void> setPinned(String id, {required bool pinned}) {
    return _ref
        .read(subjectRepositoryProvider)
        .setSubjectPinned(id, pinned: pinned);
  }

  Future<void> delete(String id) {
    return _ref.read(subjectRepositoryProvider).deleteSubject(id);
  }

  Future<String> export(String id, String destination) {
    return _ref.read(subjectRepositoryProvider).exportSubject(id, destination);
  }

  /// Writes study-notes as Markdown (clustered insights + examples).
  /// Requires a DeepSeek API key.
  Future<String> exportStudyNotes({
    required String subjectId,
    required String subjectName,
    required String destinationPath,
  }) async {
    final content = _ref.read(subjectContentProvider);
    final questions = await content.listQuestionsWithChoices(subjectId);
    if (StudyNotesBuilder.countExportable(questions) == 0) {
      throw StateError('Môn học chưa có câu hỏi để xuất tài liệu.');
    }

    final knowledgeUnits = await content.listKnowledge(subjectId);
    final summaryUnits = _knowledgeUnitsForSummary(knowledgeUnits);
    final summaryQa = <KnowledgeSummaryQa>[];
    for (final q in questions) {
      if (q.content.trim().isEmpty) continue;
      final meaning = StudyNotesBuilder.answerMeaning(q);
      final explanation = q.explanation?.trim();
      summaryQa.add(
        KnowledgeSummaryQa(
          question: _clip(q.content.trim(), 1200),
          answer: meaning == null ? null : _clip(meaning, 600),
          explanation: explanation == null || explanation.isEmpty
              ? null
              : _clip(explanation, 1200),
        ),
      );
    }

    final deepSeek = _ref.read(deepSeekClientProvider);
    final quotaFail =
        await _ref.read(backendQuotaClientProvider).consumeSolve(
              QuotaSolveKind.text,
            );
    if (quotaFail != null) {
      throw StateError(quotaFail.userMessage);
    }

    deepSeek.beginCancellableSession();
    String? insights;
    try {
      insights = await deepSeek.generateKnowledgeSummary(
        subjectName: subjectName,
        units: summaryUnits,
        questions: summaryQa.take(150).toList(),
      );
    } finally {
      deepSeek.cancelActiveSession();
    }

    final markdown = buildStudyNotesMarkdown(
      subjectName: subjectName,
      insightsMarkdown: insights,
    );

    final file = await StudyNotesBuilder.writeToFile(
      destinationPath: destinationPath,
      markdown: markdown,
    );
    return file.path;
  }

  /// Prefer theory-like units; skip rejected / empty / pure question stems.
  List<KnowledgeSummaryUnit> _knowledgeUnitsForSummary(
    List<KnowledgeUnit> units,
  ) {
    const preferred = {
      KnowledgeUnitType.theory,
      KnowledgeUnitType.definition,
      KnowledgeUnitType.formula,
      KnowledgeUnitType.theorem,
      KnowledgeUnitType.example,
      KnowledgeUnitType.solution,
      KnowledgeUnitType.note,
      KnowledgeUnitType.table,
    };
    final out = <KnowledgeSummaryUnit>[];
    for (final u in units) {
      if (!u.verificationStatus.isRetrievable) continue;
      if (!preferred.contains(u.type)) continue;
      final text = u.content.trim();
      if (text.isEmpty) continue;
      out.add(
        KnowledgeSummaryUnit(
          type: u.type.wireName,
          content: _clip(text, 2500),
        ),
      );
      if (out.length >= 120) break;
    }
    return out;
  }

  static String _clip(String text, int maxChars) {
    final one = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (one.length <= maxChars) return one;
    return '${one.substring(0, maxChars - 1).trimRight()}…';
  }

  Future<Subject> importZip(String zipPath) {
    return _ref.read(subjectRepositoryProvider).importSubject(zipPath);
  }

  Future<void> open(String id) {
    return _ref.read(subjectRepositoryProvider).openSubject(id);
  }

  Future<void> deleteSolveSession({
    required String subjectId,
    required String sessionId,
  }) async {
    await _ref.read(subjectContentProvider).deleteSolveSession(
          subjectId: subjectId,
          sessionId: sessionId,
        );
    _ref.invalidate(subjectHistoryProvider(subjectId));
    _ref.invalidate(
      subjectHistoryDetailProvider(
        (subjectId: subjectId, sessionId: sessionId),
      ),
    );
  }

  void refresh() {
    _ref.invalidate(subjectsListProvider);
  }
}

final subjectsActionsProvider = Provider<SubjectsActions>((ref) {
  return SubjectsActions(ref);
});
