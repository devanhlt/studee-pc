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
import 'package:studee_pc/data/backend/backend_quota_client.dart';
import 'package:studee_pc/data/mathpix/mathpix_text_normalizer.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_grade.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_tips.dart';
import 'package:uuid/uuid.dart';

enum PracticeStage {
  idle,
  starting,
  awaitingUser,
  thinking,
  completed,
  failed,
}

extension PracticeStageVi on PracticeStage {
  String get labelVi => switch (this) {
        PracticeStage.idle => 'Sẵn sàng',
        PracticeStage.starting => 'Đang chuẩn bị bài luyện…',
        PracticeStage.awaitingUser => 'Đang chờ bạn trả lời',
        PracticeStage.thinking => 'Đang chấm và soạn bước tiếp…',
        PracticeStage.completed => 'Đã xong',
        PracticeStage.failed => 'Không thành công',
      };

  bool get isBusy =>
      this == PracticeStage.starting || this == PracticeStage.thinking;

  bool get locksComposer =>
      this == PracticeStage.completed ||
      this == PracticeStage.starting ||
      this == PracticeStage.thinking;
}

class PracticeSessionState {
  const PracticeSessionState({
    required this.stage,
    this.sessionId,
    this.subjectId,
    this.questionText,
    this.messages = const [],
    this.currentCheckQuestion,
    this.currentChoices = const [],
    this.currentCorrectLabel,
    this.attemptsOnStep = 0,
    this.checkStepsSoFar = 0,
    this.finalSummary,
    this.errorMessage,
  });

  final PracticeStage stage;
  final String? sessionId;
  final String? subjectId;
  final String? questionText;
  final List<PracticeUiMessage> messages;
  final String? currentCheckQuestion;
  final List<PracticeChoice> currentChoices;
  /// Expected A/B for [currentChoices], used for local grading.
  final String? currentCorrectLabel;
  final int attemptsOnStep;
  /// How many check questions have been shown in this session (cap [PracticeService.maxCheckSteps]).
  final int checkStepsSoFar;
  final String? finalSummary;
  final String? errorMessage;

  /// Mid-session practice that should be kept and reopened on return.
  bool get isIncomplete =>
      stage == PracticeStage.awaitingUser ||
      stage == PracticeStage.thinking ||
      stage == PracticeStage.starting ||
      (stage == PracticeStage.failed && messages.isNotEmpty);

  PracticeSessionState copyWith({
    PracticeStage? stage,
    String? sessionId,
    String? subjectId,
    String? questionText,
    List<PracticeUiMessage>? messages,
    String? currentCheckQuestion,
    bool clearCheckQuestion = false,
    List<PracticeChoice>? currentChoices,
    bool clearChoices = false,
    String? currentCorrectLabel,
    bool clearCorrectLabel = false,
    int? attemptsOnStep,
    int? checkStepsSoFar,
    String? finalSummary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PracticeSessionState(
      stage: stage ?? this.stage,
      sessionId: sessionId ?? this.sessionId,
      subjectId: subjectId ?? this.subjectId,
      questionText: questionText ?? this.questionText,
      messages: messages ?? this.messages,
      currentCheckQuestion: clearCheckQuestion
          ? null
          : (currentCheckQuestion ?? this.currentCheckQuestion),
      currentChoices: clearChoices
          ? const []
          : (currentChoices ?? this.currentChoices),
      currentCorrectLabel: clearCorrectLabel
          ? null
          : (currentCorrectLabel ?? this.currentCorrectLabel),
      attemptsOnStep: attemptsOnStep ?? this.attemptsOnStep,
      checkStepsSoFar: checkStepsSoFar ?? this.checkStepsSoFar,
      finalSummary: finalSummary ?? this.finalSummary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Step-by-step Socratic practice (separate from one-shot [SolveService]).
class PracticeService {
  PracticeService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
    required OcrService ocr,
    required SubjectDatabaseManager databaseManager,
    BackendQuotaClient? quota,
    Uuid? uuid,
  })  : _credentials = credentials,
        _deepSeek = deepSeek,
        _ocr = ocr,
        _dbManager = databaseManager,
        _quota = quota ?? BackendQuotaClient(credentials: credentials),
        _uuid = uuid ?? const Uuid();

  static const int maxAttemptsPerStep = 2;
  static const int maxCheckSteps = 6;

  final CredentialsRepository _credentials;
  final DeepSeekClient _deepSeek;
  final OcrService _ocr;
  final SubjectDatabaseManager _dbManager;
  final BackendQuotaClient _quota;
  final Uuid _uuid;
  final AppLogger _log = AppLogger('PracticeService');

  final StreamController<PracticeSessionState> _states =
      StreamController<PracticeSessionState>.broadcast();

  PracticeSessionState _state =
      const PracticeSessionState(stage: PracticeStage.idle);
  final List<PracticeLlmMessage> _history = [];
  bool _cancelled = false;
  String? _activeOcrJobId;
  ParsedQuestion? _parsed;

  Stream<PracticeSessionState> get states => _states.stream;
  PracticeSessionState get current => _state;

  bool get hasIncompleteSession => _state.isIncomplete;

  /// Restore an incomplete session for [subjectId] (memory first, then DB draft).
  Future<bool> restoreIncompleteIfNeeded(String subjectId) async {
    if (_state.isIncomplete && _state.subjectId == subjectId) {
      return true;
    }
    if (_state.isIncomplete &&
        _state.subjectId != null &&
        _state.subjectId != subjectId) {
      // Another subject's practice is still open in memory.
      return false;
    }
    if (_state.stage != PracticeStage.idle &&
        _state.stage != PracticeStage.completed) {
      return _state.isIncomplete && _state.subjectId == subjectId;
    }

    try {
      await _dbManager.open(subjectId);
      final db = _dbManager.requireActive();
      final rows = await (db.select(db.solveSessions)
            ..where((t) => t.status.equals('practice_running'))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .get();
      if (rows.isEmpty) return false;
      final row = rows.first;
      final raw = row.parsedQuestionJson;
      if (raw == null || raw.trim().isEmpty) return false;
      final draft = jsonDecode(raw);
      if (draft is! Map) return false;
      return _hydrateFromDraft(
        subjectId: subjectId,
        sessionId: row.id,
        draft: Map<String, dynamic>.from(draft),
        questionFallback: row.rawInputText,
      );
    } on Object catch (e) {
      _log.warning('Practice restore failed: ${e.runtimeType}');
      return false;
    }
  }

  Future<bool> hasApiKey() => _credentials.hasDeepSeekApiKey();

  Future<void> prepareCredentials() async {
    try {
      await _credentials.loadAll();
    } on Object catch (e) {
      _log.warning('prepareCredentials failed: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Result<void>> startFromText({
    required String subjectId,
    required String text,
    String inputType = 'practice_text',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Chưa có câu hỏi. Hãy dán đề vào trước nhé.',
        code: 'question_empty',
      );
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return const Failure(f);
    }
    return _startSession(
      subjectId: subjectId,
      questionText: trimmed,
      inputType: inputType,
    );
  }

  Future<Result<void>> startFromImage({
    required String subjectId,
    required Uint8List bytes,
    String inputType = 'practice_image',
  }) async {
    if (bytes.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Ảnh không có nội dung. Chọn hoặc chụp lại nhé.',
        code: 'image_empty',
      );
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return const Failure(f);
    }

    _cancelled = false;
    final sessionId = _uuid.v4();
    _emit(
      PracticeSessionState(
        stage: PracticeStage.starting,
        sessionId: sessionId,
        subjectId: subjectId,
        messages: const [],
      ),
    );

    try {
      await prepareCredentials();
      if (!await hasApiKey()) {
        throw const MissingApiKeyFailure(
          userMessage: 'Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.',
        );
      }
      final ocr = await _ocrImageToText(bytes, sessionId);
      if (ocr.isFailure) {
        final f = ocr.failureOrNull!;
        _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
        return Failure(f);
      }
      if (_cancelled) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }
      return await _startSession(
        subjectId: subjectId,
        questionText: ocr.valueOrNull!.text,
        inputType: inputType,
        sessionId: sessionId,
      );
    } on AppFailure catch (f) {
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return Failure(f);
    } on Object catch (e) {
      final f = UnknownFailure(
        userMessage: 'Chưa bắt đầu được bài luyện. Thử lại nhé.',
        code: 'practice_start_failed',
        details: e.runtimeType.toString(),
      );
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return Failure(f);
    }
  }

  Future<Result<void>> _startSession({
    required String subjectId,
    required String questionText,
    required String inputType,
    String? sessionId,
  }) async {
    _cancelled = false;
    _history.clear();
    _parsed = null;
    final id = sessionId ?? _uuid.v4();

    try {
      await _dbManager.open(subjectId);
      await _abandonIncompleteSessions(exceptSessionId: id);
    } on Object catch (_) {}

    _emit(
      PracticeSessionState(
        stage: PracticeStage.starting,
        sessionId: id,
        subjectId: subjectId,
        questionText: questionText,
        messages: [
          PracticeUiMessage(
            id: _uuid.v4(),
            role: PracticeMessageRole.system,
            text: 'Câu hỏi:\n$questionText',
          ),
        ],
      ),
    );

    try {
      await prepareCredentials();
      if (!await hasApiKey()) {
        throw const MissingApiKeyFailure(
          userMessage: 'Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.',
        );
      }

      final quotaFail = await _quota.consumeOneSolve();
      if (quotaFail != null) {
        _emit(_state.copyWith(
          stage: PracticeStage.failed,
          errorMessage: quotaFail.userMessage,
        ));
        return Failure(quotaFail);
      }

      await _insertSession(
        sessionId: id,
        inputType: inputType,
        rawText: questionText,
      );

      _deepSeek.beginCancellableSession();

      try {
        _parsed = await _deepSeek.parseQuestion(
          ParseQuestionRequest(rawText: questionText),
        );
      } on Object catch (_) {
        _parsed = null;
      }
      if (_cancelled) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }

      final turn = await _deepSeek.startPracticeTurn(
        questionText: questionText,
        parsed: _parsed,
        maxCheckSteps: maxCheckSteps,
      );
      if (_cancelled) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }

      _history.add(
        PracticeLlmMessage(
          role: 'user',
          content: jsonEncode({
            'action': 'start',
            'question_text': questionText,
          }),
        ),
      );
      if (turn.rawJson != null) {
        _history.add(
          PracticeLlmMessage(role: 'assistant', content: turn.rawJson!),
        );
      }

      _applyCoachTurn(turn, resetAttempts: true);
      return const Success(null);
    } on AppFailure catch (f) {
      if (f is CancelledFailure || f.code == 'cancelled') {
        _emit(const PracticeSessionState(stage: PracticeStage.idle));
        return Failure(f);
      }
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return Failure(f);
    } on Object catch (e) {
      final f = UnknownFailure(
        userMessage: 'Chưa bắt đầu được bài luyện. Thử lại nhé.',
        code: 'practice_start_failed',
        details: e.runtimeType.toString(),
      );
      _emit(_state.copyWith(stage: PracticeStage.failed, errorMessage: f.userMessage));
      return Failure(f);
    }
  }

  Future<Result<void>> submitAnswer(String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      const f = ValidationFailure(
        userMessage: 'Bạn chưa nhập câu trả lời.',
        code: 'answer_empty',
      );
      return const Failure(f);
    }
    if (_state.stage == PracticeStage.completed) {
      const f = ValidationFailure(
        userMessage: 'Bài luyện đã kết thúc. Bấm “Câu hỏi mới” để luyện tiếp.',
        code: 'practice_locked',
      );
      return const Failure(f);
    }
    if (_state.stage != PracticeStage.awaitingUser) {
      const f = ValidationFailure(
        userMessage: 'Đang xử lý, chờ một chút nhé.',
        code: 'practice_busy',
      );
      return const Failure(f);
    }

    final attempts = _state.attemptsOnStep + 1;
    final msgs = [
      ..._state.messages,
      PracticeUiMessage(
        id: _uuid.v4(),
        role: PracticeMessageRole.user,
        text: trimmed,
      ),
    ];
    _emit(
      _state.copyWith(
        stage: PracticeStage.thinking,
        messages: msgs,
        attemptsOnStep: attempts,
        clearError: true,
      ),
    );

    try {
      final turn = await _deepSeek.continuePracticeTurn(
        history: List.unmodifiable(_history),
        userAnswer: trimmed,
        attemptsOnStep: attempts,
        checkStepsSoFar: _state.checkStepsSoFar,
        maxCheckSteps: maxCheckSteps,
      );
      if (_cancelled) {
        return const Failure(CancelledFailure(code: 'cancelled'));
      }

      _history.add(
        PracticeLlmMessage(
          role: 'user',
          content: jsonEncode({
            'action': 'answer',
            'user_answer': trimmed,
            'attempts_on_step': attempts,
          }),
        ),
      );
      if (turn.rawJson != null) {
        _history.add(
          PracticeLlmMessage(role: 'assistant', content: turn.rawJson!),
        );
      }

      final eval = turn.evaluation;
      var feedbackText = eval?.feedback.trim() ?? '';
      final coachText = turn.coachMessage.trim();
      final localCorrect = PracticeMcqGrade.grade(
        answer: trimmed,
        correctLabel: _state.currentCorrectLabel,
        choices: _state.currentChoices,
      );
      // Prefer local MCQ grade when we know the expected label.
      final correct = localCorrect ?? (eval?.correct == true);
      if (localCorrect != null && localCorrect != (eval?.correct == true)) {
        _log.info(
          'Practice local grade override local=$localCorrect llm=${eval?.correct}',
        );
        if (feedbackText.isEmpty ||
            (localCorrect &&
                !RegExp(r'(chính xác|đúng|hoàn toàn)', caseSensitive: false)
                    .hasMatch(feedbackText)) ||
            (!localCorrect &&
                RegExp(r'(chính xác|hoàn toàn đúng)', caseSensitive: false)
                    .hasMatch(feedbackText))) {
          feedbackText = localCorrect
              ? 'Chính xác!'
              : 'Chưa đúng. Thử lại hoặc chọn đáp án còn lại nhé.';
        }
      }
      final forceAdvance = !correct && attempts >= maxAttemptsPerStep;
      final advancing = correct || forceAdvance || turn.isComplete;

      // Drop grade text that already spoils the next check question/choices.
      feedbackText = PracticeMcqGrade.sanitizeFeedback(
        feedback: feedbackText,
        correct: correct,
        nextCheck: turn.checkQuestion,
        nextChoices: turn.checkChoices,
      );

      var nextMessages = List<PracticeUiMessage>.from(_state.messages);

      // One reply bubble after the user answer (avoid Nhận xét + Gia sư duplicates).
      final reply = _singleAnswerReply(
        turn: turn,
        feedbackText: feedbackText,
        coachText: coachText,
      );
      if (reply != null) {
        nextMessages = [
          ...nextMessages,
          PracticeUiMessage(
            id: _uuid.v4(),
            role: PracticeMessageRole.feedback,
            text: reply,
          ),
        ];
      }

      if (forceAdvance &&
          turn.reveal != null &&
          turn.reveal!.trim().isNotEmpty &&
          !_similarText(reply ?? '', turn.reveal!.trim())) {
        nextMessages = [
          ...nextMessages,
          PracticeUiMessage(
            id: _uuid.v4(),
            role: PracticeMessageRole.coach,
            text: 'Gợi ý: ${turn.reveal!.trim()}',
          ),
        ];
      }

      _emit(_state.copyWith(messages: nextMessages));
      unawaited(_checkpointDraft());

      if (advancing) {
        _applyCoachTurn(
          turn,
          resetAttempts: true,
          // Reply already shown; only add next check / completion bookkeeping.
          skipDuplicateCoach: true,
          skipFinalSummaryIfSimilarTo: reply,
        );
      } else {
        _emit(
          _state.copyWith(
            stage: PracticeStage.awaitingUser,
            attemptsOnStep: attempts,
          ),
        );
      }
      return const Success(null);
    } on AppFailure catch (f) {
      if (f is CancelledFailure || f.code == 'cancelled') {
        return Failure(f);
      }
      _emit(
        _state.copyWith(
          stage: PracticeStage.awaitingUser,
          errorMessage: f.userMessage,
        ),
      );
      return Failure(f);
    } on Object catch (e) {
      final f = UnknownFailure(
        userMessage: 'Chưa chấm được câu trả lời. Gửi lại giúp mình nhé.',
        code: 'practice_grade_failed',
        details: e.runtimeType.toString(),
      );
      _emit(
        _state.copyWith(
          stage: PracticeStage.awaitingUser,
          errorMessage: f.userMessage,
        ),
      );
      return Failure(f);
    }
  }

  void _applyCoachTurn(
    PracticeTurnResponse turn, {
    required bool resetAttempts,
    bool skipDuplicateCoach = false,
    String? skipFinalSummaryIfSimilarTo,
  }) {
    var msgs = List<PracticeUiMessage>.from(_state.messages);
    var coach = turn.coachMessage.trim();
    var check = turn.checkQuestion?.trim();
    var choices = turn.checkChoices;
    var hasCheck = check != null && check.isNotEmpty;
    var isComplete = turn.isComplete;
    var summary = turn.finalSummary?.trim();
    var mcqTip = turn.mcqTip?.trim();

    // Hard cap: never show more than [maxCheckSteps] check questions.
    if (!isComplete && hasCheck && _state.checkStepsSoFar >= maxCheckSteps) {
      isComplete = true;
      hasCheck = false;
      check = null;
      choices = const [];
      summary ??= coach.isNotEmpty
          ? coach
          : 'Đã hoàn thành các bước luyện cho bài này.';
      coach = '';
    }

    // When a check question is present, emit a single coach bubble (avoid
    // duplicate open question + MCQ restatement).
    if (!skipDuplicateCoach && !hasCheck && !isComplete && coach.isNotEmpty) {
      PracticeUiMessage? lastCoach;
      for (var i = msgs.length - 1; i >= 0; i--) {
        if (msgs[i].role == PracticeMessageRole.coach ||
            msgs[i].role == PracticeMessageRole.feedback) {
          lastCoach = msgs[i];
          break;
        }
      }
      if (lastCoach == null || !_similarText(lastCoach.text, coach)) {
        msgs = [
          ...msgs,
          PracticeUiMessage(
            id: _uuid.v4(),
            role: PracticeMessageRole.coach,
            text: coach,
          ),
        ];
      }
    }

    if (isComplete) {
      if (summary != null &&
          summary.isNotEmpty &&
          (skipFinalSummaryIfSimilarTo == null ||
              !_similarText(skipFinalSummaryIfSimilarTo, summary))) {
        msgs = [
          ...msgs,
          PracticeUiMessage(
            id: _uuid.v4(),
            role: PracticeMessageRole.system,
            text: summary,
          ),
        ];
      }
      // One MCQ strategy tip at the end (LLM first, heuristic fallback).
      var tip = (mcqTip != null && mcqTip.isNotEmpty)
          ? mcqTip
          : PracticeMcqTips.pick(
              question: _state.questionText ??
                  _state.currentCheckQuestion ??
                  summary ??
                  '',
              choices: _state.currentChoices.map((c) => c.display).toList(),
              context: '${_state.questionText ?? ''}\n$coach\n${summary ?? ''}',
              seed: msgs.length,
            );
      if (!tip.startsWith('Mẹo:') && !tip.startsWith('Mẹo :')) {
        tip = 'Mẹo: $tip';
      }
      msgs = [
        ...msgs,
        PracticeUiMessage(
          id: _uuid.v4(),
          role: PracticeMessageRole.system,
          text: tip,
        ),
      ];
      _emit(
        _state.copyWith(
          stage: PracticeStage.completed,
          messages: msgs,
          clearCheckQuestion: true,
          clearChoices: true,
          clearCorrectLabel: true,
          attemptsOnStep: 0,
          finalSummary: summary ?? skipFinalSummaryIfSimilarTo,
          clearError: true,
        ),
      );
      unawaited(_persistCompleted());
      return;
    }

    var nextStepCount = _state.checkStepsSoFar;
    if (hasCheck) {
      nextStepCount = _state.checkStepsSoFar + 1;
      final choiceLines = choices.isEmpty
          ? ''
          : '\n${choices.map((c) => c.display).join('\n')}';
      final leadIn = (!skipDuplicateCoach &&
              coach.isNotEmpty &&
              !_similarText(coach, check!))
          ? '$coach\n\n'
          : '';
      msgs = [
        ...msgs,
        PracticeUiMessage(
          id: _uuid.v4(),
          role: PracticeMessageRole.coach,
          text: '$leadIn$check$choiceLines',
        ),
      ];
    }

    _emit(
      _state.copyWith(
        stage: PracticeStage.awaitingUser,
        messages: msgs,
        currentCheckQuestion: check,
        currentChoices: choices,
        currentCorrectLabel: turn.correctLabel,
        clearCorrectLabel: turn.correctLabel == null,
        attemptsOnStep: resetAttempts ? 0 : _state.attemptsOnStep,
        checkStepsSoFar: nextStepCount,
        clearError: true,
      ),
    );
    unawaited(_checkpointDraft());
  }

  /// Prefer one post-answer line: feedback, else coach, else final summary.
  static String? _singleAnswerReply({
    required PracticeTurnResponse turn,
    required String feedbackText,
    required String coachText,
  }) {
    if (turn.isComplete) {
      final summary = turn.finalSummary?.trim() ?? '';
      if (summary.isNotEmpty) return summary;
      if (coachText.isNotEmpty) return coachText;
      if (feedbackText.isNotEmpty) return feedbackText;
      return null;
    }
    if (feedbackText.isNotEmpty && coachText.isNotEmpty) {
      if (_similarText(feedbackText, coachText)) return feedbackText;
      // Distinct next-step coaching is added later via check_question;
      // keep a single grade bubble here.
      return feedbackText;
    }
    if (feedbackText.isNotEmpty) return feedbackText;
    if (coachText.isNotEmpty) return coachText;
    return null;
  }

  static bool _similarText(String a, String b) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[!.…]'), '')
        .trim();
    final na = norm(a);
    final nb = norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;
    // Shared math / answer token often means duplicate praise.
    final math = RegExp(r'\$[^$]+\$');
    final ma = math.allMatches(a).map((m) => m.group(0)).toSet();
    final mb = math.allMatches(b).map((m) => m.group(0)).toSet();
    if (ma.isNotEmpty && mb.isNotEmpty && ma.intersection(mb).isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> cancel() async {
    _cancelled = true;
    _deepSeek.cancelActiveSession();
    final ocrJob = _activeOcrJobId;
    if (ocrJob != null) {
      try {
        await _ocr.cancel(ocrJob);
      } on Object catch (_) {}
    }
    await _markSessionCancelled(_state.sessionId);
    _history.clear();
    _parsed = null;
    _emit(const PracticeSessionState(stage: PracticeStage.idle));
  }

  void reset() {
    _cancelled = false;
    final sessionId = _state.sessionId;
    _history.clear();
    _parsed = null;
    _deepSeek.cancelActiveSession();
    unawaited(_markSessionCancelled(sessionId));
    _emit(const PracticeSessionState(stage: PracticeStage.idle));
  }

  void dispose() {
    _deepSeek.cancelActiveSession();
    _states.close();
  }

  void _emit(PracticeSessionState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  bool _hydrateFromDraft({
    required String subjectId,
    required String sessionId,
    required Map<String, dynamic> draft,
    String? questionFallback,
  }) {
    final messagesRaw = draft['messages'];
    final messages = <PracticeUiMessage>[];
    if (messagesRaw is List) {
      for (final item in messagesRaw) {
        if (item is Map) {
          messages.add(
            PracticeUiMessage.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    if (messages.isEmpty) return false;

    final choicesRaw = draft['current_choices'];
    final choices = <PracticeChoice>[];
    if (choicesRaw is List) {
      for (final item in choicesRaw) {
        if (item is Map) {
          final c = PracticeChoice.fromJson(Map<String, dynamic>.from(item));
          if (c.label.isNotEmpty && c.content.isNotEmpty) choices.add(c);
        }
      }
    }

    _history
      ..clear()
      ..addAll(_historyFromDraft(draft['history']));
    _parsed = null;
    _cancelled = false;
    _deepSeek.beginCancellableSession();

    final check = (draft['current_check_question'] ?? '').toString().trim();
    _emit(
      PracticeSessionState(
        stage: PracticeStage.awaitingUser,
        sessionId: sessionId,
        subjectId: subjectId,
        questionText: () {
          final q = (draft['question_text'] ?? '').toString().trim();
          if (q.isNotEmpty) return q;
          final fallback = (questionFallback ?? '').trim();
          return fallback.isEmpty ? null : fallback;
        }(),
        messages: messages,
        currentCheckQuestion: check.isEmpty ? null : check,
        currentChoices: choices,
        currentCorrectLabel: () {
          final label =
              (draft['current_correct_label'] ?? '').toString().trim().toUpperCase();
          return (label == 'A' || label == 'B') ? label : null;
        }(),
        attemptsOnStep: (draft['attempts_on_step'] as num?)?.toInt() ?? 0,
        checkStepsSoFar: (draft['check_steps_so_far'] as num?)?.toInt() ?? 0,
      ),
    );
    _log.info('Restored incomplete practice id=$sessionId');
    return true;
  }

  List<PracticeLlmMessage> _historyFromDraft(Object? raw) {
    final out = <PracticeLlmMessage>[];
    if (raw is! List) return out;
    for (final item in raw) {
      if (item is! Map) continue;
      final role = (item['role'] ?? '').toString();
      final content = (item['content'] ?? '').toString();
      if (role.isEmpty || content.isEmpty) continue;
      out.add(PracticeLlmMessage(role: role, content: content));
    }
    return out;
  }

  Future<void> _checkpointDraft() async {
    final sessionId = _state.sessionId;
    if (sessionId == null || !_state.isIncomplete) return;
    // Persist a resumable snapshot while waiting for the user (or mid-turn).
    if (_state.stage != PracticeStage.awaitingUser &&
        _state.stage != PracticeStage.failed) {
      return;
    }
    try {
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final draft = <String, dynamic>{
        'v': 1,
        'subject_id': _state.subjectId,
        'stage': _state.stage.name,
        'question_text': _state.questionText,
        'attempts_on_step': _state.attemptsOnStep,
        'check_steps_so_far': _state.checkStepsSoFar,
        'current_check_question': _state.currentCheckQuestion,
        'current_choices':
            _state.currentChoices.map((c) => c.toJson()).toList(),
        'current_correct_label': _state.currentCorrectLabel,
        'messages': _state.messages.map((m) => m.toJson()).toList(),
        'history': _history.map((m) => m.toApiMap()).toList(),
      };
      await (db.update(db.solveSessions)..where((t) => t.id.equals(sessionId)))
          .write(
        SolveSessionsCompanion(
          parsedQuestionJson: Value(jsonEncode(draft)),
          status: const Value('practice_running'),
          updatedAt: Value(now),
        ),
      );
    } on Object catch (e) {
      _log.warning('Practice checkpoint failed: ${e.runtimeType}');
    }
  }

  Future<void> _abandonIncompleteSessions({String? exceptSessionId}) async {
    try {
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final q = db.update(db.solveSessions)
        ..where((t) => t.status.equals('practice_running'));
      if (exceptSessionId != null) {
        q.where((t) => t.id.equals(exceptSessionId).not());
      }
      await q.write(
        SolveSessionsCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(now),
        ),
      );
    } on Object catch (_) {}
  }

  Future<void> _markSessionCancelled(String? sessionId) async {
    if (sessionId == null) return;
    try {
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (db.update(db.solveSessions)..where((t) => t.id.equals(sessionId)))
          .write(
        SolveSessionsCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(now),
        ),
      );
    } on Object catch (_) {}
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
            status: 'practice_running',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _persistCompleted() async {
    final sessionId = _state.sessionId;
    if (sessionId == null) return;
    try {
      final db = _dbManager.requireActive();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final transcript = _state.messages
          .map((m) {
            final who = switch (m.role) {
              PracticeMessageRole.coach => 'Trợ lý Stud',
              PracticeMessageRole.user => 'Bạn',
              PracticeMessageRole.feedback => 'Nhận xét',
              PracticeMessageRole.system => 'Ghi chú',
            };
            return '**$who:** ${m.text}';
          })
          .join('\n\n');

      await (db.update(db.solveSessions)..where((t) => t.id.equals(sessionId)))
          .write(
        SolveSessionsCompanion(
          status: const Value('practice_completed'),
          updatedAt: Value(now),
        ),
      );

      await db.into(db.solveResults).insert(
            SolveResultsCompanion.insert(
              id: _uuid.v4(),
              sessionId: sessionId,
              questionType: 'text_response',
              finalAnswerContent: Value(_state.finalSummary),
              shortAnswer: const Value('Luyện tập'),
              explanationMarkdown: Value(transcript),
              confidenceLevel: 'medium',
              createdAt: now,
            ),
          );
      _log.info('Persisted practice session id=$sessionId');
    } on Object catch (e) {
      _log.warning('Practice persist failed: ${e.runtimeType}');
    }
  }

  Future<Result<_OcrText>> _ocrImageToText(
    Uint8List bytes,
    String sessionId,
  ) async {
    _activeOcrJobId = sessionId;
    try {
      final temp = await getTemporaryDirectory();
      final input = File(p.join(temp.path, 'practice_$sessionId.png'));
      await input.writeAsBytes(bytes, flush: true);
      final outDir = p.join(temp.path, 'practice_ocr_$sessionId');
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
                final map = jsonDecode(await file.readAsString())
                    as Map<String, dynamic>;
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
      final polished = await _deepSeek.polishOcrText(
        raw: raw,
        heuristic: base,
      );
      final out = polished.trim().isEmpty ? base : polished.trim();
      return MathpixTextNormalizer.normalize(out);
    } on Object catch (_) {
      return base;
    }
  }
}

class _OcrText {
  const _OcrText({required this.text, this.confidence});
  final String text;
  final double? confidence;
}
