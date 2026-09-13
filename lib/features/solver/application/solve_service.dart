import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/backend/backend_quota_client.dart';
import 'package:studee_pc/data/deepseek/response_validator.dart';
import 'package:studee_pc/data/mathpix/mathpix_text_normalizer.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/entities/solve_result.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/knowledge_retriever.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';
import 'package:studee_pc/domain/services/confidence_calculator.dart';
import 'package:studee_pc/domain/services/evidence_builder.dart';
import 'package:uuid/uuid.dart';

/// Pipeline stages exposed to the solver / overlay UI.
enum SolvePipelineStage {
  idle,
  capturing,
  recognizing,
  parsing,
  retrieving,
  generating,
  completed,
  partialFailure,
  offlineFailure,
}

extension SolvePipelineStageVi on SolvePipelineStage {
  String get labelVi => switch (this) {
        SolvePipelineStage.idle => 'Sẵn sàng',
        SolvePipelineStage.capturing => 'Đang chụp màn hình…',
        SolvePipelineStage.recognizing => 'Đang nhận dạng văn bản…',
        SolvePipelineStage.parsing => 'Đang phân tích câu hỏi…',
        SolvePipelineStage.retrieving => 'Đang tìm kiến thức liên quan…',
        SolvePipelineStage.generating => 'Đang tạo câu trả lời…',
        SolvePipelineStage.completed => 'Hoàn tất',
        SolvePipelineStage.partialFailure => 'Hoàn tất một phần',
        SolvePipelineStage.offlineFailure => 'Không kết nối được',
      };

  /// True while work is in flight (spinner / Hủy should cancel).
  bool get isInProgress => switch (this) {
        SolvePipelineStage.capturing ||
        SolvePipelineStage.recognizing ||
        SolvePipelineStage.parsing ||
        SolvePipelineStage.retrieving ||
        SolvePipelineStage.generating =>
          true,
        _ => false,
      };

  /// Finished success or failure — no spinner.
  bool get isTerminal => switch (this) {
        SolvePipelineStage.completed ||
        SolvePipelineStage.partialFailure ||
        SolvePipelineStage.offlineFailure ||
        SolvePipelineStage.idle =>
          true,
        _ => false,
      };
}

class SolveSessionState {
  const SolveSessionState({
    required this.stage,
    this.sessionId,
    this.rawText,
    this.ocrConfidence,
    this.needsOcrReview = false,
    this.needsQuestionConfirm = false,
    this.parsedQuestion,
    this.result,
    this.errorMessage,
    this.warnings = const [],
  });

  final SolvePipelineStage stage;
  final String? sessionId;
  final String? rawText;
  final double? ocrConfidence;
  final bool needsOcrReview;
  /// User must confirm/edit question before re-solving ("Giải lại").
  final bool needsQuestionConfirm;
  final ParsedQuestion? parsedQuestion;
  final SolveResult? result;
  final String? errorMessage;
  final List<String> warnings;

  SolveSessionState copyWith({
    SolvePipelineStage? stage,
    String? sessionId,
    String? rawText,
    double? ocrConfidence,
    bool? needsOcrReview,
    bool? needsQuestionConfirm,
    ParsedQuestion? parsedQuestion,
    SolveResult? result,
    String? errorMessage,
    List<String>? warnings,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SolveSessionState(
      stage: stage ?? this.stage,
      sessionId: sessionId ?? this.sessionId,
      rawText: rawText ?? this.rawText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      needsOcrReview: needsOcrReview ?? this.needsOcrReview,
      needsQuestionConfirm:
          needsQuestionConfirm ?? this.needsQuestionConfirm,
      parsedQuestion: parsedQuestion ?? this.parsedQuestion,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warnings: warnings ?? this.warnings,
    );
  }
}

/// Coordinates OCR → parse → retrieve → evidence → DeepSeek → validate.
class SolveService {
  SolveService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
    required OcrService ocr,
    required KnowledgeRetriever retriever,
    required SubjectDatabaseManager databaseManager,
    AnswerPrecedence precedence = const AnswerPrecedence(),
    EvidenceBuilder evidenceBuilder = const EvidenceBuilder(),
    ConfidenceCalculator confidenceCalculator = const ConfidenceCalculator(),
    ResponseValidator validator = const ResponseValidator(),
    BackendQuotaClient? quota,
    Uuid? uuid,
  })  : _credentials = credentials,
        _deepSeek = deepSeek,
        _ocr = ocr,
        _retriever = retriever,
        _dbManager = databaseManager,
        _precedence = precedence,
        _evidenceBuilder = evidenceBuilder,
        _confidence = confidenceCalculator,
        _validator = validator,
        _quota = quota ?? BackendQuotaClient(credentials: credentials),
        _uuid = uuid ?? const Uuid();

  final CredentialsRepository _credentials;
  final DeepSeekClient _deepSeek;
  final OcrService _ocr;
  final KnowledgeRetriever _retriever;
  final SubjectDatabaseManager _dbManager;
  final AnswerPrecedence _precedence;
  final EvidenceBuilder _evidenceBuilder;
  final ConfidenceCalculator _confidence;
  final ResponseValidator _validator;
  final BackendQuotaClient _quota;
  final Uuid _uuid;
  final AppLogger _log = AppLogger('SolveService');

  final StreamController<SolveSessionState> _states =
      StreamController<SolveSessionState>.broadcast();
  SolveSessionState _state = const SolveSessionState(stage: SolvePipelineStage.idle);
  bool _cancelled = false;
  String? _activeOcrJobId;

  Stream<SolveSessionState> get states => _states.stream;
  SolveSessionState get current => _state;

  Future<bool> hasApiKey() => _credentials.hasDeepSeekApiKey();

  Future<Result<SolveResult>> solveFromText({
    required String subjectId,
    required String text,
    String inputType = 'pasted_text',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Câu hỏi không được trống.',
        code: 'question_empty',
      );
      _emitFailure(f);
      return const Failure(f);
    }

    _cancelled = false;
    final sessionId = _uuid.v4();
    _emit(
      SolveSessionState(
        stage: SolvePipelineStage.parsing,
        sessionId: sessionId,
        rawText: trimmed,
      ),
    );

    try {
      await prepareCredentials();
      await _dbManager.open(subjectId);
      await _insertSession(
        sessionId: sessionId,
        inputType: inputType,
        rawText: trimmed,
      );
      return _runPipeline(
        subjectId: subjectId,
        sessionId: sessionId,
        rawText: trimmed,
      );
    } on AppFailure catch (f) {
      _emitFailure(f);
      return Failure(f);
    } on Object catch (e) {
      final f = UnknownFailure(
        userMessage: 'Giải câu hỏi thất bại.',
        code: 'solve_failed',
        details: e.runtimeType.toString(),
      );
      _emitFailure(f);
      return Failure(f);
    }
  }

  Future<Result<SolveResult>> solveFromImage({
    required String subjectId,
    required Uint8List bytes,
    String inputType = 'image',
  }) async {
    if (bytes.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Ảnh trống — hãy chọn hoặc chụp lại.',
        code: 'image_empty',
      );
      _emitFailure(f);
      return const Failure(f);
    }

    _cancelled = false;
    final sessionId = _uuid.v4();
    _emit(
      SolveSessionState(
        stage: SolvePipelineStage.recognizing,
        sessionId: sessionId,
      ),
    );

    try {
      await prepareCredentials();
      await _dbManager.open(subjectId);
      await _insertSession(
        sessionId: sessionId,
        inputType: inputType,
        rawText: null,
      );

      final ocrText = await _ocrImageToText(bytes, sessionId);
      if (ocrText.isFailure) return Failure(ocrText.failureOrNull!);

      final text = ocrText.valueOrNull!;
      final lowConfidence = text.confidence != null && text.confidence! < 0.65;

      _emit(
        _state.copyWith(
          stage: lowConfidence
              ? SolvePipelineStage.parsing
              : SolvePipelineStage.parsing,
          rawText: text.text,
          ocrConfidence: text.confidence,
          needsOcrReview: lowConfidence,
        ),
      );

      if (lowConfidence) {
        // Pause for UI OCR edit — caller should call [continueWithReviewedText].
        return const Failure(
          ValidationFailure(
            userMessage:
                'Độ tin cậy OCR thấp. Hãy kiểm tra và chỉnh sửa văn bản.',
            code: 'ocr_review_required',
          ),
        );
      }

      return _runPipeline(
        subjectId: subjectId,
        sessionId: sessionId,
        rawText: text.text,
      );
    } on AppFailure catch (f) {
      _emitFailure(f);
      return Failure(f);
    } on Object catch (e) {
      final f = UnknownFailure(
        userMessage: 'Giải câu hỏi từ ảnh thất bại.',
        code: 'solve_image_failed',
        details: e.runtimeType.toString(),
      );
      _emitFailure(f);
      return Failure(f);
    }
  }

  /// Resume after the user edits low-confidence OCR text.
  Future<Result<SolveResult>> continueWithReviewedText({
    required String subjectId,
    required String reviewedText,
  }) async {
    final trimmed = reviewedText.trim();
    if (trimmed.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Nội dung câu hỏi không được trống.',
        code: 'reviewed_text_empty',
      );
      _emitFailure(f);
      return const Failure(f);
    }

    final sessionId = _state.sessionId ?? _uuid.v4();
    _cancelled = false;
    _emit(
      _state.copyWith(
        stage: SolvePipelineStage.parsing,
        rawText: trimmed,
        needsOcrReview: false,
        needsQuestionConfirm: false,
        clearError: true,
        clearResult: true,
      ),
    );
    try {
      await prepareCredentials();
      await _dbManager.open(subjectId);
      return _runPipeline(
        subjectId: subjectId,
        sessionId: sessionId,
        rawText: trimmed,
      );
    } on AppFailure catch (f) {
      _emitFailure(f);
      return Failure(f);
    }
  }

  Future<Result<SolveResult>> resolveAgain({
    required String subjectId,
  }) async {
    final text = _state.rawText;
    if (text == null || text.trim().isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không có câu hỏi để giải lại.',
          code: 'no_question_to_retry',
        ),
      );
    }
    return solveFromText(subjectId: subjectId, text: text);
  }

  /// Enter edit/confirm mode for "Giải lại" instead of solving immediately.
  Result<void> beginResolveAgain() {
    final text = _state.rawText;
    if (text == null || text.trim().isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không có câu hỏi để giải lại.',
          code: 'no_question_to_retry',
        ),
      );
    }
    _emit(
      _state.copyWith(
        stage: SolvePipelineStage.idle,
        needsQuestionConfirm: true,
        needsOcrReview: false,
        clearResult: true,
        clearError: true,
        rawText: text,
      ),
    );
    return const Success(null);
  }

  /// Warm Keychain once before OCR / DeepSeek (avoids multiple unlock prompts).
  Future<void> prepareCredentials() async {
    try {
      await _credentials.loadAll();
    } on Object catch (e) {
      _log.warning('prepareCredentials failed: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Result<void>> markIncorrect({
    required String note,
    String? subjectId,
  }) async {
    final result = _state.result;
    if (result == null) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có kết quả để đánh dấu sai.',
          code: 'no_result',
        ),
      );
    }
    try {
      final db = subjectId != null
          ? await _dbManager.open(subjectId)
          : _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.into(db.userFeedback).insert(
            UserFeedbackCompanion.insert(
              id: _uuid.v4(),
              resultId: result.id,
              feedbackType: 'incorrect',
              note: Value(note.trim().isEmpty ? null : note.trim()),
              createdAt: now,
            ),
          );
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không lưu được phản hồi.',
          code: 'feedback_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> saveResultToSubject({
    required String subjectId,
  }) async {
    final result = _state.result;
    final question = _state.parsedQuestion;
    if (result == null || question == null) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có kết quả để lưu.',
          code: 'no_result_to_save',
        ),
      );
    }
    try {
      final db = await _dbManager.open(subjectId);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final sourceId = _uuid.v4();
      await db.into(db.sources).insert(
            SourcesCompanion.insert(
              id: sourceId,
              type: 'pasted_text',
              title: 'Kết quả giải ${_shortId(result.id)}',
              contentSha256: Fingerprints.contentHash(question.content),
              pageCount: const Value(1),
              processingStatus: 'completed',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final unitId = _uuid.v4();
      final unitContent =
          '${question.content}\n\nĐáp án: ${result.finalAnswerLabel ?? ''} '
          '${result.finalAnswerContent ?? result.shortAnswer ?? ''}'.trim();
      await db.into(db.knowledgeUnits).insert(
            KnowledgeUnitsCompanion.insert(
              id: unitId,
              sourceId: sourceId,
              type: KnowledgeUnitType.solution.wireName,
              content: unitContent,
              normalizedContent: TextNormalizer.normalize(unitContent),
              verificationStatus: VerificationStatus.unreviewed.wireName,
              contentHash: Fingerprints.contentHash(unitContent),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final qId = _uuid.v4();
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: qId,
              knowledgeUnitId: unitId,
              questionType: question.questionType.wireName,
              content: question.content,
              normalizedContent:
                  TextNormalizer.normalizeQuestionText(question.content),
              questionFingerprint: Fingerprints.questionFingerprint(
                questionText: question.content,
                choiceContents: question.choiceContents,
              ),
              answerLabel: Value(result.finalAnswerLabel),
              answerContent: Value(result.finalAnswerContent),
              explanation: Value(result.explanationMarkdown),
              verificationStatus: VerificationStatus.unreviewed.wireName,
              createdAt: now,
              updatedAt: now,
            ),
          );
      var order = 0;
      for (final choice in question.choices) {
        await db.into(db.questionChoices).insert(
              QuestionChoicesCompanion.insert(
                id: _uuid.v4(),
                questionId: qId,
                label: choice.label,
                content: choice.content,
                normalizedContent:
                    TextNormalizer.normalizeChoiceContent(choice.content),
                sortOrder: order++,
              ),
            );
      }
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không lưu kết quả vào môn học.',
          code: 'save_result_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    _deepSeek.cancelActiveSession();
    final ocrJob = _activeOcrJobId;
    if (ocrJob != null) {
      try {
        await _ocr.cancel(ocrJob);
      } on Object {
        // Best-effort.
      }
    }
    _activeOcrJobId = null;
    _emit(
      const SolveSessionState(
        stage: SolvePipelineStage.idle,
        errorMessage: 'Đã hủy giải câu hỏi.',
      ),
    );
  }

  void reset() {
    _cancelled = false;
    _deepSeek.cancelActiveSession();
    _activeOcrJobId = null;
    _emit(const SolveSessionState(stage: SolvePipelineStage.idle));
  }

  Future<void> dispose() async {
    await _states.close();
  }

  Future<Result<SolveResult>> _runPipeline({
    required String subjectId,
    required String sessionId,
    required String rawText,
  }) async {
    // Keychain / API key only when DeepSeek is about to be called.
    final gate = await _requireApiKey();
    if (gate != null) {
      _emitFailure(gate);
      return Failure(gate);
    }

    // One solve = one question pipeline (OCR hops + N LLM calls count as 1).
    final quotaFailure = await _quota.consumeOneSolve();
    if (quotaFailure != null) {
      _emitFailure(quotaFailure);
      return Failure(quotaFailure);
    }

    _cancelled = false;
    _deepSeek.beginCancellableSession();

    if (_cancelled) {
      return const Failure(CancelledFailure(code: 'cancelled'));
    }

    _emit(
      _state.copyWith(
        stage: SolvePipelineStage.parsing,
        sessionId: sessionId,
        rawText: rawText,
        clearError: true,
      ),
    );

    late final ParsedQuestion parsed;
    try {
      parsed = await _deepSeek.parseQuestion(
        ParseQuestionRequest(rawText: rawText),
      );
    } on AppFailure catch (f) {
      if (_cancelled || f is CancelledFailure) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }
      _emit(
        _state.copyWith(
          stage: SolvePipelineStage.offlineFailure,
          errorMessage: f.userMessage,
        ),
      );
      return Failure(f);
    }
    if (_cancelled) {
      return const Failure(CancelledFailure(code: 'cancelled'));
    }

    _emit(_state.copyWith(
      stage: SolvePipelineStage.retrieving,
      parsedQuestion: parsed,
    ));

    final retrieval = await _retriever.retrieve(
      subjectId: subjectId,
      question: parsed,
      limit: 20,
    );

    final decision = _precedence.resolve(
      currentQuestion: parsed,
      candidates: retrieval.candidates,
    );

    // Conflict: keep going to the LLM with all conflicting Q+A pairs as
    // evidence (fixed=false). Do not lock a single imported answer.
    final evidenceCandidates = decision is TrustedConflictDecision
        ? _mergeConflictCandidates(
            decision.allCandidates,
            retrieval.candidates,
          )
        : retrieval.candidates;

    final evidence = _evidenceBuilder.build(
      currentQuestion: parsed,
      rankedCandidates: evidenceCandidates,
      decision: decision,
    );

    if (_cancelled) {
      return const Failure(CancelledFailure(code: 'cancelled'));
    }

    _emit(_state.copyWith(stage: SolvePipelineStage.generating));

    DeepSeekAnswerResponse answer;
    try {
      answer = await _deepSeek.generateAnswer(
        GenerateAnswerRequest(evidencePackage: evidence),
      );
    } on AppFailure catch (f) {
      if (_cancelled || f is CancelledFailure) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }
      _emit(
        _state.copyWith(
          stage: SolvePipelineStage.offlineFailure,
          errorMessage: f.userMessage,
        ),
      );
      return Failure(f);
    }
    if (_cancelled) {
      return const Failure(CancelledFailure(code: 'cancelled'));
    }

    var validation = _validator.validate(
      response: answer,
      package: evidence,
    );

    // Prefer local coerce over a repair round-trip (prefix / paraphrase drift).
    if (validation is Failure<DeepSeekAnswerResponse> &&
        !evidence.answerConstraint.fixed) {
      final local = _coerceUnfixedAnswer(
        answer: answer,
        package: evidence,
        modelKnowledge: decision.modelKnowledgeDisclosure,
      );
      if (local != null) {
        _log.info('Accepted answer via local coerce (skipped repair)');
        answer = local;
        validation = Success(answer);
      }
    }

    if (validation is Failure<DeepSeekAnswerResponse>) {
      final firstErrors = _validator.collectErrors(
        response: answer,
        package: evidence,
      );
      _log.warning(
        'Answer validation failed errors=${firstErrors.join(",")} '
        'fixed=${evidence.answerConstraint.fixed}',
      );
      _emit(
        _state.copyWith(
          stage: SolvePipelineStage.generating,
          errorMessage:
              'Phản hồi AI chưa khớp. Đang thử lại…',
        ),
      );
      try {
        answer = await _deepSeek.repairResponse(
          RepairResponseRequest(
            evidencePackage: evidence,
            invalidResponse: answer.rawJson ?? jsonEncode(answer.toJson()),
            validationErrors: firstErrors.isEmpty
                ? const ['format']
                : firstErrors,
          ),
        );
        if (_cancelled) {
          return const Failure(CancelledFailure(code: 'cancelled'));
        }
        validation = _validator.validate(
          response: answer,
          package: evidence,
        );
        if (validation is Failure<DeepSeekAnswerResponse>) {
          final details = validation.failure.details;
          _log.warning('Answer repair still invalid details=$details');

          if (evidence.answerConstraint.fixed) {
            answer = DeepSeekAnswerResponse(
              questionType: answer.questionType,
              finalAnswerLabel: evidence.answerConstraint.answerLabel ??
                  answer.finalAnswerLabel,
              finalAnswerContent: evidence.answerConstraint.answerContent ??
                  answer.finalAnswerContent,
              shortAnswer: evidence.answerConstraint.answerLabel ??
                  answer.shortAnswer,
              explanationMarkdown: answer.explanationMarkdown,
              usedEvidenceIds: evidence.evidence
                  .take(3)
                  .map((e) => e.evidenceId)
                  .toList(),
              modelKnowledgeUsed: false,
              missingInformation: answer.missingInformation,
              warnings: [
                ...answer.warnings,
                'Đáp án lấy từ kiến thức đã nhập; phần giải thích giữ từ AI.',
              ],
              rawJson: answer.rawJson,
            );
            validation = Success(answer);
          } else {
            final coerced = _coerceUnfixedAnswer(
              answer: answer,
              package: evidence,
              modelKnowledge: true,
            );
            if (coerced != null) {
              _log.warning(
                'Repair still invalid; coercing unfixed answer for display',
              );
              answer = coerced;
              validation = Success(answer);
            } else {
              // Absolute last resort: never leave the user with only "Thử lại"
              // when the model already produced an explanation.
              final fallback = _forceDisplayAnswer(
                answer: answer,
                modelKnowledge: true,
              );
              if (fallback != null) {
                answer = fallback;
                validation = Success(answer);
              } else {
                final f = ValidationFailure(
                  userMessage:
                      'Phản hồi AI vẫn không hợp lệ sau khi sửa. Thử giải lại.',
                  code: 'deepseek_response_invalid',
                  details: details,
                );
                _emit(
                  _state.copyWith(
                    stage: SolvePipelineStage.partialFailure,
                    errorMessage: f.userMessage,
                  ),
                );
                return Failure(f);
              }
            }
          }
        }
        answer = validation.valueOrNull!;
      } on AppFailure catch (f) {
        if (_cancelled || f is CancelledFailure) {
          return const Failure(CancelledFailure(code: 'cancelled'));
        }
        if (evidence.answerConstraint.fixed) {
          _log.warning('Repair failed with ${f.code}; using fixed stored answer');
          answer = DeepSeekAnswerResponse(
            questionType: answer.questionType,
            finalAnswerLabel: evidence.answerConstraint.answerLabel ??
                answer.finalAnswerLabel,
            finalAnswerContent: evidence.answerConstraint.answerContent ??
                answer.finalAnswerContent,
            shortAnswer: evidence.answerConstraint.answerLabel ??
                answer.shortAnswer,
            explanationMarkdown: answer.explanationMarkdown,
            usedEvidenceIds: evidence.evidence
                .take(3)
                .map((e) => e.evidenceId)
                .toList(),
            modelKnowledgeUsed: false,
            missingInformation: answer.missingInformation,
            warnings: [
              ...answer.warnings,
              'Đáp án lấy từ kiến thức đã nhập.',
            ],
            rawJson: answer.rawJson,
          );
        } else {
          final local = _coerceUnfixedAnswer(
                answer: answer,
                package: evidence,
                modelKnowledge: true,
              ) ??
              _forceDisplayAnswer(answer: answer, modelKnowledge: true);
          if (local != null) {
            _log.warning('Repair API failed; displaying coerced model answer');
            answer = local;
          } else {
            _emit(
              _state.copyWith(
                stage: SolvePipelineStage.offlineFailure,
                errorMessage: f.userMessage,
              ),
            );
            return Failure(f);
          }
        }
      }
    } else {
      answer = validation.valueOrNull!;
    }

    // Enforce fixed answer constraint in application code.
    var finalLabel = answer.finalAnswerLabel;
    var finalContent = answer.finalAnswerContent;
    var modelUsed = answer.modelKnowledgeUsed || decision.modelKnowledgeDisclosure;
    if (evidence.answerConstraint.fixed) {
      finalLabel = evidence.answerConstraint.answerLabel ?? finalLabel;
      finalContent = evidence.answerConstraint.answerContent ?? finalContent;
      modelUsed = false;
    }

    final confidence = _confidence.calculate(
      decision: decision,
      evidenceCandidates: retrieval.candidates,
    );

    final references = <ResultReference>[];
    for (final item in evidence.evidence) {
      if (!answer.usedEvidenceIds.contains(item.evidenceId) &&
          answer.usedEvidenceIds.isNotEmpty) {
        continue;
      }
      references.add(
        ResultReference(
          id: _uuid.v4(),
          localId: item.localId,
          evidenceId: item.evidenceId,
          type: item.type,
          sourceTitle: item.sourceTitle,
          page: item.page,
          snippet: item.content.length > 160
              ? '${item.content.substring(0, 157)}...'
              : item.content,
        ),
      );
    }
    if (references.isEmpty) {
      for (final item in evidence.evidence.take(5)) {
        references.add(
          ResultReference(
            id: _uuid.v4(),
            localId: item.localId,
            evidenceId: item.evidenceId,
            type: item.type,
            sourceTitle: item.sourceTitle,
            page: item.page,
            snippet: item.content.length > 160
                ? '${item.content.substring(0, 157)}...'
                : item.content,
          ),
        );
      }
    }

    final warnings = <String>[
      ...parsed.warnings,
      ...evidence.warnings,
      ...answer.warnings,
      if (decision.modelKnowledgeDisclosure)
        'Sinh từ kiến thức của mô hình',
    ];
    final dedupedWarnings = <String>[];
    final seenWarnings = <String>{};
    for (final w in warnings) {
      final trimmed = w.trim();
      if (trimmed.isEmpty || !seenWarnings.add(trimmed)) continue;
      dedupedWarnings.add(trimmed);
    }

    final result = SolveResult(
      id: _uuid.v4(),
      sessionId: sessionId,
      questionType: parsed.questionType,
      finalAnswerLabel: finalLabel,
      finalAnswerContent: finalContent,
      shortAnswer: answer.shortAnswer ?? finalLabel,
      explanationMarkdown: answer.explanationMarkdown,
      confidence: confidence,
      modelKnowledgeUsed: modelUsed,
      missingInformation: answer.missingInformation,
      warnings: dedupedWarnings,
      usedEvidenceIds: answer.usedEvidenceIds,
      references: references,
      createdAt: DateTime.now().toUtc(),
    );

    await _persistResult(result, parsed);

    _emit(
      _state.copyWith(
        stage: SolvePipelineStage.completed,
        result: result,
        parsedQuestion: parsed,
        warnings: dedupedWarnings,
        clearError: true,
      ),
    );
    _log.info('Solve completed session=$sessionId');
    return Success(result);
  }

  /// Put every conflicting Q+A pair first, then remaining retrieval hits.
  List<RankedCandidate> _mergeConflictCandidates(
    List<RankedCandidate> conflicting,
    List<RankedCandidate> all,
  ) {
    final seen = <String>{};
    final out = <RankedCandidate>[];
    for (final c in conflicting) {
      if (seen.add(c.localId)) out.add(c);
    }
    for (final c in all) {
      if (seen.add(c.localId)) out.add(c);
    }
    return out;
  }

  /// Soft-accept a model answer when strict validation fails.
  DeepSeekAnswerResponse? _coerceUnfixedAnswer({
    required DeepSeekAnswerResponse answer,
    required EvidencePackage package,
    required bool modelKnowledge,
  }) {
    final retry = _validator.validate(response: answer, package: package);
    if (retry is Success<DeepSeekAnswerResponse>) {
      final v = retry.value;
      return DeepSeekAnswerResponse(
        questionType: v.questionType,
        finalAnswerLabel: v.finalAnswerLabel,
        finalAnswerContent: v.finalAnswerContent,
        shortAnswer: v.shortAnswer,
        explanationMarkdown: v.explanationMarkdown,
        usedEvidenceIds: v.usedEvidenceIds,
        modelKnowledgeUsed: modelKnowledge || v.modelKnowledgeUsed,
        missingInformation: v.missingInformation,
        warnings: [
          ...v.warnings,
          if (modelKnowledge || v.modelKnowledgeUsed)
            'Sinh từ kiến thức của mô hình',
        ],
        rawJson: v.rawJson ?? answer.rawJson,
      );
    }
    return _forceDisplayAnswer(
      answer: answer,
      modelKnowledge: modelKnowledge,
      choices: package.currentQuestion.choices,
    );
  }

  /// Always surface something usable when the model produced text.
  DeepSeekAnswerResponse? _forceDisplayAnswer({
    required DeepSeekAnswerResponse answer,
    required bool modelKnowledge,
    List<ParsedChoice>? choices,
  }) {
    var label = answer.finalAnswerLabel?.trim();
    var content = answer.finalAnswerContent?.trim();
    final short = answer.shortAnswer?.trim();
    final explanation = answer.explanationMarkdown.trim();

    if ((label == null || label.isEmpty) &&
        short != null &&
        RegExp(r'^[A-Da-d]\.?$').hasMatch(short)) {
      label = short.replaceAll('.', '').toUpperCase();
    }

    final choiceList = choices ?? const <ParsedChoice>[];
    if (label != null && label.isNotEmpty && choiceList.isNotEmpty) {
      final needle = label.toUpperCase().replaceFirst(RegExp(r'[.\)\-–:：]+$'), '');
      for (final c in choiceList) {
        if (c.label.trim().toUpperCase() == needle) {
          return DeepSeekAnswerResponse(
            questionType: answer.questionType,
            finalAnswerLabel: c.label,
            finalAnswerContent: c.content,
            shortAnswer: short ?? c.label,
            explanationMarkdown: explanation.isNotEmpty
                ? explanation
                : answer.explanationMarkdown,
            usedEvidenceIds: const [],
            modelKnowledgeUsed: true,
            missingInformation: answer.missingInformation,
            warnings: [
              ...answer.warnings,
              'Hiển thị đáp án mô hình (tin cậy thấp).',
            ],
            rawJson: answer.rawJson,
          );
        }
      }
    }

    final body = (content != null && content.isNotEmpty)
        ? content
        : (short != null && short.isNotEmpty)
            ? short
            : explanation;
    if (body.isEmpty) return null;

    return DeepSeekAnswerResponse(
      questionType: answer.questionType,
      finalAnswerLabel: label,
      finalAnswerContent: body,
      shortAnswer: short ?? label,
      explanationMarkdown:
          explanation.isNotEmpty ? explanation : body,
      usedEvidenceIds: const [],
      modelKnowledgeUsed: true,
      missingInformation: answer.missingInformation,
      warnings: [
        ...answer.warnings,
        'Hiển thị câu trả lời mô hình (tin cậy thấp).',
      ],
      rawJson: answer.rawJson,
    );
  }

  Future<Result<_OcrText>> _ocrImageToText(
    Uint8List bytes,
    String sessionId,
  ) async {
    _activeOcrJobId = sessionId;
    try {
      final temp = await getTemporaryDirectory();
      final input = File(p.join(temp.path, 'solve_$sessionId.png'));
      await input.writeAsBytes(bytes, flush: true);
      final outDir = p.join(temp.path, 'solve_ocr_$sessionId');
      await Directory(outDir).create(recursive: true);

      String? text;
      String? rawText;
      double? confidence;
      String? fail;

      await for (final event in _ocr.process(
        OcrRequest(
          jobId: sessionId,
          action: 'parse_image',
          inputPath: input.path,
          outputDirectory: outDir,
          languageHints: const ['vi', 'en'],
        ),
      )) {
        if (_cancelled) {
          return const Failure(CancelledFailure(code: 'cancelled'));
        }
        switch (event) {
          case OcrPageCompletedEvent(:final resultPath):
            final file = File(
              resultPath.startsWith('/')
                  ? resultPath
                  : p.join(outDir, resultPath),
            );
            if (await file.exists()) {
              try {
                final map =
                    jsonDecode(await file.readAsString()) as Map<String, dynamic>;
                text = (map['text'] ?? map['normalized_text'] ?? '') as String?;
                rawText = map['raw_text'] as String?;
                confidence = (map['confidence'] as num?)?.toDouble();
              } on Object {
                text = await file.readAsString();
              }
            }
          case OcrFailedEvent(:final message, :final code):
            fail = message ?? code;
          case OcrCompletedEvent():
            break;
          case OcrProgressEvent():
          case OcrWarningEvent():
            break;
        }
      }

      if (text == null || text.trim().isEmpty) {
        return Failure(
          OcrFailure(
            userMessage: fail ??
                'Không nhận dạng được văn bản. Hãy dán văn bản thủ công.',
            code: 'ocr_empty',
          ),
        );
      }

      final polished = await _polishOcrText(
        raw: rawText ?? text,
        heuristic: text,
      );
      return Success(_OcrText(text: polished, confidence: confidence));
    } finally {
      _activeOcrJobId = null;
    }
  }

  /// Optional LLM polish when heuristic OCR still looks broken.
  Future<String> _polishOcrText({
    required String raw,
    required String heuristic,
  }) async {
    final normalized = MathpixTextNormalizer.normalize(raw);
    final base = normalized.trim().isEmpty ? heuristic : normalized;
    if (!MathpixTextNormalizer.shouldPolishWithLlm(raw, base)) {
      return base;
    }
    try {
      _log.info('OCR polish: calling DeepSeek (heuristic still looks unsafe)');
      final polished = await _deepSeek.polishOcrText(
        raw: raw,
        heuristic: base,
      );
      final out = polished.trim().isEmpty ? base : polished.trim();
      return MathpixTextNormalizer.normalize(out);
    } on AppFailure catch (f) {
      _log.warning('OCR polish skipped code=${f.code}');
      return base;
    } on Object catch (e) {
      _log.warning('OCR polish unexpected: ${e.runtimeType}');
      return base;
    }
  }

  Future<void> _insertSession({
    required String sessionId,
    required String inputType,
    required String? rawText,
  }) async {
    final db = _dbManager.requireActive();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.into(db.solveSessions).insert(
          SolveSessionsCompanion.insert(
            id: sessionId,
            inputType: inputType,
            rawInputText: Value(rawText),
            status: 'running',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _persistResult(
    SolveResult result,
    ParsedQuestion parsed,
  ) async {
    final db = _dbManager.requireActive();
    final now = result.createdAt.millisecondsSinceEpoch;
    final sessionId = result.sessionId;
    if (sessionId != null) {
      await (db.update(db.solveSessions)..where((t) => t.id.equals(sessionId)))
          .write(
        SolveSessionsCompanion(
          status: const Value('completed'),
          parsedQuestionJson: Value(
            jsonEncode({
              'question_type': parsed.questionType.wireName,
              'content': parsed.content,
              'choices': parsed.choices
                  .map((c) => {'label': c.label, 'content': c.content})
                  .toList(),
            }),
          ),
          updatedAt: Value(now),
        ),
      );
    }

    await db.into(db.solveResults).insert(
          SolveResultsCompanion.insert(
            id: result.id,
            sessionId: result.sessionId ?? sessionId ?? result.id,
            questionType: result.questionType.wireName,
            finalAnswerLabel: Value(result.finalAnswerLabel),
            finalAnswerContent: Value(result.finalAnswerContent),
            shortAnswer: Value(result.shortAnswer),
            explanationMarkdown: Value(result.explanationMarkdown),
            confidenceLevel: result.confidence.wireName,
            modelKnowledgeUsed: Value(result.modelKnowledgeUsed ? 1 : 0),
            missingInformation: Value(result.missingInformation ? 1 : 0),
            warningsJson: Value(jsonEncode(result.warnings)),
            promptVersion: Value(result.promptVersion),
            createdAt: now,
          ),
        );

    var order = 0;
    for (final ref in result.references) {
      await db.into(db.resultReferences).insert(
            ResultReferencesCompanion.insert(
              id: ref.id,
              resultId: result.id,
              evidenceId: ref.evidenceId ?? ref.localId,
              localId: ref.localId,
              sourceTitle: Value(ref.sourceTitle),
              page: Value(ref.page),
              sortOrder: order++,
            ),
          );
    }
  }

  Future<AppFailure?> _requireApiKey() async {
    if (!await _credentials.hasActivationCode()) {
      return const MissingApiKeyFailure(
        userMessage: 'Nhập mã kích hoạt trong Cài đặt.',
      );
    }
    return null;
  }

  void _emit(SolveSessionState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  void _emitFailure(AppFailure f) {
    final offline = f is NetworkFailure ||
        f is AuthFailure ||
        f is RateLimitFailure ||
        f is QuotaFailure ||
        f is MissingApiKeyFailure;
    _emit(
      _state.copyWith(
        stage: offline
            ? SolvePipelineStage.offlineFailure
            : SolvePipelineStage.partialFailure,
        errorMessage: f.userMessage,
      ),
    );
  }

  static String _shortId(String id) =>
      id.length <= 8 ? id : id.substring(0, 8);
}

class _OcrText {
  const _OcrText({required this.text, this.confidence});
  final String text;
  final double? confidence;
}
