import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/widgets/question_display_format.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/backend/backend_quota_client.dart';
import 'package:studee_pc/data/backend/quota_tokens.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_grade.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_tips.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/features/review/application/review_answer_style.dart';
import 'package:studee_pc/features/review/application/review_question_text.dart';
import 'package:studee_pc/features/review/application/review_quiz_config.dart';
import 'package:studee_pc/features/subjects/application/study_notes_builder.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

enum ReviewStage { idle, running, completed }

/// How Ôn tập presents each saved question.
enum ReviewPlayMode {
  /// Raw question first, then Socratic Stud coach (Luyện-style).
  coach,

  /// Raw question + multiple-choice pick (no coach).
  quiz,
}

class ReviewSessionState {
  const ReviewSessionState({
    required this.stage,
    this.mode = ReviewPlayMode.coach,
    this.subjectId,
    this.total = 0,
    this.currentIndex = 0,
    this.completedCount = 0,
    this.errorMessage,
    this.quizSelectedLabel,
    this.quizIsCorrect,
    this.quizAnswered = false,
    this.quizTip,
    this.quizTipLoading = false,
    this.quizCorrectLabel,
    this.quizCorrectContent,
    this.quizAnswerFromLlm = false,
    this.quizResolvingAnswer = false,
    this.quizLatexLoading = false,
    this.quizRemaining = Duration.zero,
    this.quizTimedOut = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
  });

  final ReviewStage stage;
  final ReviewPlayMode mode;
  final String? subjectId;
  final int total;
  final int currentIndex;
  final int completedCount;
  final String? errorMessage;
  final String? quizSelectedLabel;
  final bool? quizIsCorrect;
  final bool quizAnswered;
  final String? quizTip;
  final bool quizTipLoading;
  /// Effective correct label (stored or LLM-resolved).
  final String? quizCorrectLabel;
  final String? quizCorrectContent;
  final bool quizAnswerFromLlm;
  final bool quizResolvingAnswer;
  final bool quizLatexLoading;
  /// Remaining time for Ôn tập (fixed 30 min exam).
  final Duration quizRemaining;
  final bool quizTimedOut;
  /// Graded correct answers in this run (Giải đề).
  final int correctCount;
  /// Graded incorrect answers in this run (Giải đề).
  final int incorrectCount;

  bool get isIncomplete => stage == ReviewStage.running;

  bool get isLastQuestion => total > 0 && currentIndex >= total - 1;

  int get displayNumber => total == 0 ? 0 : currentIndex + 1;

  int get answeredCount => correctCount + incorrectCount;

  int get unansweredCount {
    final left = total - answeredCount;
    return left < 0 ? 0 : left;
  }

  double get progress {
    if (total <= 0) return 0;
    return (completedCount / total).clamp(0.0, 1.0);
  }

  /// Accuracy over graded answers only (0–1). Null when none graded.
  double? get accuracy {
    if (answeredCount <= 0) return null;
    return correctCount / answeredCount;
  }

  ReviewSessionState copyWith({
    ReviewStage? stage,
    ReviewPlayMode? mode,
    String? subjectId,
    int? total,
    int? currentIndex,
    int? completedCount,
    String? errorMessage,
    bool clearError = false,
    String? quizSelectedLabel,
    bool? quizIsCorrect,
    bool? quizAnswered,
    String? quizTip,
    bool? quizTipLoading,
    String? quizCorrectLabel,
    String? quizCorrectContent,
    bool? quizAnswerFromLlm,
    bool? quizResolvingAnswer,
    bool? quizLatexLoading,
    Duration? quizRemaining,
    bool? quizTimedOut,
    int? correctCount,
    int? incorrectCount,
    bool clearQuiz = false,
    bool clearQuizTip = false,
  }) {
    return ReviewSessionState(
      stage: stage ?? this.stage,
      mode: mode ?? this.mode,
      subjectId: subjectId ?? this.subjectId,
      total: total ?? this.total,
      currentIndex: currentIndex ?? this.currentIndex,
      completedCount: completedCount ?? this.completedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      quizSelectedLabel:
          clearQuiz ? null : (quizSelectedLabel ?? this.quizSelectedLabel),
      quizIsCorrect: clearQuiz ? null : (quizIsCorrect ?? this.quizIsCorrect),
      quizAnswered: clearQuiz ? false : (quizAnswered ?? this.quizAnswered),
      quizTip: clearQuiz || clearQuizTip ? null : (quizTip ?? this.quizTip),
      quizTipLoading: clearQuiz
          ? false
          : quizTipLoading != null
              ? quizTipLoading
              : (clearQuizTip ? false : this.quizTipLoading),
      quizCorrectLabel:
          clearQuiz ? null : (quizCorrectLabel ?? this.quizCorrectLabel),
      quizCorrectContent:
          clearQuiz ? null : (quizCorrectContent ?? this.quizCorrectContent),
      quizAnswerFromLlm:
          clearQuiz ? false : (quizAnswerFromLlm ?? this.quizAnswerFromLlm),
      quizResolvingAnswer: clearQuiz
          ? false
          : (quizResolvingAnswer ?? this.quizResolvingAnswer),
      quizLatexLoading:
          clearQuiz ? false : (quizLatexLoading ?? this.quizLatexLoading),
      quizRemaining: quizRemaining ?? this.quizRemaining,
      quizTimedOut: quizTimedOut ?? this.quizTimedOut,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }
}

/// Walks every saved question — either MCQ quiz or Socratic coach.
class ReviewService {
  ReviewService({
    required PracticeService practice,
    required DeepSeekClient deepSeek,
    required BackendQuotaClient quota,
    required Future<List<Question>> Function(String subjectId) loadQuestions,
    required Future<void> Function({
      required String subjectId,
      required String questionId,
      required String content,
      List<({String id, String content})> choices,
      String? answerContent,
    }) persistQuestionMath,
    required Future<void> Function({
      required String subjectId,
      required String questionId,
    }) incrementPracticeCount,
    required Future<void> Function({
      required String subjectId,
      required String questionId,
    }) incrementIncorrectCount,
    required Future<SubjectFormatContext> Function(String subjectId)
        resolveFormatKind,
  })  : _practice = practice,
        _deepSeek = deepSeek,
        _quota = quota,
        _loadQuestions = loadQuestions,
        _persistQuestionMath = persistQuestionMath,
        _incrementPracticeCount = incrementPracticeCount,
        _incrementIncorrectCount = incrementIncorrectCount,
        _resolveFormatKind = resolveFormatKind;

  final PracticeService _practice;
  final DeepSeekClient _deepSeek;
  final BackendQuotaClient _quota;
  final Future<List<Question>> Function(String subjectId) _loadQuestions;
  final Future<void> Function({
    required String subjectId,
    required String questionId,
    required String content,
    List<({String id, String content})> choices,
    String? answerContent,
  }) _persistQuestionMath;
  final Future<void> Function({
    required String subjectId,
    required String questionId,
  }) _incrementPracticeCount;
  final Future<void> Function({
    required String subjectId,
    required String questionId,
  }) _incrementIncorrectCount;
  final Future<SubjectFormatContext> Function(String subjectId)
      _resolveFormatKind;
  final AppLogger _log = AppLogger('ReviewService');
  SubjectFormatContext _formatContext = SubjectFormatContext.empty;
  SubjectFormatKind get _formatKind => _formatContext.kind;

  final StreamController<ReviewSessionState> _states =
      StreamController<ReviewSessionState>.broadcast();

  ReviewSessionState _state = const ReviewSessionState(stage: ReviewStage.idle);
  List<Question> _queue = const [];
  bool _countedCurrent = false;
  StreamSubscription<PracticeSessionState>? _practiceSub;
  int _quizTipRequestId = 0;
  final Map<String, QuizAnswerResolution> _llmAnswers = {};
  Timer? _quizTicker;
  DateTime? _quizEndsAt;


  Stream<ReviewSessionState> get states => _states.stream;
  ReviewSessionState get current => _state;
  bool get hasIncompleteSession => _state.isIncomplete;

  Question? get currentQuestion {
    if (_state.stage != ReviewStage.running) return null;
    if (_queue.isEmpty || _state.currentIndex >= _queue.length) return null;
    return _queue[_state.currentIndex];
  }

  /// Up to four choices for the current quiz question.
  List<QuestionChoice> get currentQuizChoices {
    final q = currentQuestion;
    if (q == null) return const [];
    final sorted = [...q.choices]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.take(4).toList();
  }

  Future<Result<void>> start(
    String subjectId, {
    ReviewPlayMode mode = ReviewPlayMode.coach,
  }) async {
    if (_state.stage == ReviewStage.running) {
      await cancel();
    }

    try {
      _formatContext = await _resolveFormatKind(subjectId);
    } on Object catch (_) {
      _formatContext = SubjectFormatContext.empty;
    }

    List<Question> questions;
    try {
      questions = (await _loadQuestions(subjectId))
          .where((q) => q.content.trim().isNotEmpty)
          .toList();
    } on Object catch (e) {
      _log.warning('Load review questions failed: ${e.runtimeType}');
      const f = DatabaseFailure(
        userMessage: 'Không tải được câu hỏi để ôn tập.',
        code: 'review_load_failed',
      );
      _emit(_state.copyWith(stage: ReviewStage.idle, errorMessage: f.userMessage));
      return const Failure(f);
    }

    if (questions.isEmpty) {
      const f = ValidationFailure(
        userMessage:
            'Chưa có câu hỏi đã lưu. Hãy nhập tài liệu ở Kiến thức trước nhé.',
        code: 'review_empty',
      );
      _emit(_state.copyWith(stage: ReviewStage.idle, errorMessage: f.userMessage));
      return const Failure(f);
    }

    final queue = buildShuffledQuizSet(questions);
    _queue = queue;
    _countedCurrent = false;
    _llmAnswers.clear();
    if (mode == ReviewPlayMode.coach) {
      _watchPractice();
    } else {
      _practiceSub?.cancel();
      _practiceSub = null;
    }
    _emit(
      ReviewSessionState(
        stage: ReviewStage.running,
        mode: mode,
        subjectId: subjectId,
        total: queue.length,
        currentIndex: 0,
        completedCount: 0,
        correctCount: 0,
        incorrectCount: 0,
        quizRemaining: ReviewQuizConfig.duration,
      ),
    );
    _startQuizCountdown();
    return _startCurrent();
  }

  Future<Result<void>> continueNext() async {
    if (_state.stage != ReviewStage.running) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên ôn tập.',
          code: 'review_inactive',
        ),
      );
    }
    if (_state.mode == ReviewPlayMode.quiz) {
      if (!_state.quizAnswered && currentQuizChoices.isNotEmpty) {
        return const Failure(
          ValidationFailure(
            userMessage: 'Hãy chọn đáp án trước khi sang câu tiếp.',
            code: 'review_quiz_not_answered',
          ),
        );
      }
    } else if (_practice.current.stage != PracticeStage.completed) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Hãy xong câu hiện tại trước khi sang câu tiếp.',
          code: 'review_not_ready',
        ),
      );
    }
    _markCurrentComplete();
    if (_state.isLastQuestion) {
      _completeRun();
      return const Success(null);
    }
    _countedCurrent = false;
    _emit(
      _state.copyWith(
        currentIndex: _state.currentIndex + 1,
        clearError: true,
        clearQuiz: true,
      ),
    );
    return _startCurrent();
  }

  Future<Result<void>> retryCurrent() async {
    if (_state.stage != ReviewStage.running) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên ôn tập.',
          code: 'review_inactive',
        ),
      );
    }
    _countedCurrent = false;
    _emit(_state.copyWith(clearQuiz: true, clearError: true));
    return _startCurrent();
  }

  /// Grade a multiple-choice pick in quiz mode.
  Future<Result<void>> submitQuizChoice(QuestionChoice choice) async {
    if (_state.stage != ReviewStage.running ||
        _state.mode != ReviewPlayMode.quiz) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên giải đề.',
          code: 'review_inactive',
        ),
      );
    }
    if (_state.quizAnswered || _state.quizResolvingAnswer) {
      return const Success(null);
    }

    final question = currentQuestion;
    if (question == null) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không có câu hỏi hiện tại.',
          code: 'review_no_question',
        ),
      );
    }

    final choices = currentQuizChoices
        .map(
          (c) => PracticeChoice(
            label: c.label,
            content: c.content,
          ),
        )
        .toList();

    var correctLabel = question.answerLabel?.trim();
    var correctContent =
        StudyNotesBuilder.answerMeaning(question, compact: false);
    var fromLlm = false;

    if (!_hasStoredAnswer(question)) {
      final cached = _llmAnswers[question.id];
      if (cached != null) {
        correctLabel = cached.label;
        correctContent = cached.content;
        fromLlm = true;
      } else {
        try {
          await _practice.prepareCredentials();
        } on Object catch (_) {}
        if (!await _practice.hasApiKey()) {
          const fail = MissingApiKeyFailure();
          _emit(
            _state.copyWith(
              quizSelectedLabel: choice.label,
              quizResolvingAnswer: false,
              errorMessage: fail.userMessage,
            ),
          );
          return const Failure(fail);
        }

        _emit(
          _state.copyWith(
            quizSelectedLabel: choice.label,
            quizResolvingAnswer: true,
            clearError: true,
          ),
        );
        final resolved = await _resolveAnswerWithLlm(question, choices);
        if (_state.stage != ReviewStage.running ||
            currentQuestion?.id != question.id) {
          return const Success(null);
        }
        if (resolved == null) {
          _emit(
            _state.copyWith(
              quizResolvingAnswer: false,
              quizSelectedLabel: choice.label,
              errorMessage: _state.errorMessage ??
                  'Chưa suy luận được đáp án. Thử lại nhé.',
            ),
          );
          return const Failure(
            ValidationFailure(
              userMessage: 'Chưa suy luận được đáp án. Thử lại nhé.',
              code: 'review_answer_resolve_failed',
            ),
          );
        }
        correctLabel = resolved.label;
        correctContent = resolved.content;
        fromLlm = true;
      }
    }

    var isCorrect = PracticeMcqGrade.grade(
      answer: choice.label.isNotEmpty
          ? '${choice.label}. ${choice.content}'.trim()
          : choice.content,
      correctLabel: correctLabel,
      choices: choices,
    );

    if (isCorrect == null &&
        correctContent != null &&
        correctContent.trim().isNotEmpty) {
      final meaning = correctContent.trim().toLowerCase();
      final picked = choice.content.trim().toLowerCase();
      if (picked.isNotEmpty) {
        isCorrect = picked == meaning ||
            meaning.contains(picked) ||
            picked.contains(meaning);
      }
    }

    final gradedCorrect = isCorrect ?? false;
    _emit(
      _state.copyWith(
        quizSelectedLabel: choice.label,
        quizIsCorrect: gradedCorrect,
        quizAnswered: true,
        quizResolvingAnswer: false,
        quizCorrectLabel: correctLabel,
        quizCorrectContent: correctContent,
        quizAnswerFromLlm: fromLlm,
        correctCount:
            gradedCorrect ? _state.correctCount + 1 : _state.correctCount,
        incorrectCount:
            gradedCorrect ? _state.incorrectCount : _state.incorrectCount + 1,
        clearError: true,
      ),
    );
    _markCurrentComplete();
    if (!gradedCorrect) {
      final subjectId = _state.subjectId;
      if (subjectId != null) {
        unawaited(_recordIncorrect(subjectId, question.id));
      }
    }
    return const Success(null);
  }

  /// User tapped "Gợi ý" — load one tip for the current question.
  Future<Result<void>> requestQuizTip() async {
    if (_state.stage != ReviewStage.running ||
        _state.mode != ReviewPlayMode.quiz) {
      return const Success(null);
    }
    if (_state.quizResolvingAnswer) {
      return const Success(null);
    }
    if (_state.quizTipLoading) return const Success(null);
    if (_state.quizTip != null && _state.quizTip!.trim().isNotEmpty) {
      return const Success(null);
    }

    try {
      await _practice.prepareCredentials();
    } on Object catch (_) {}
    if (!await _practice.hasApiKey()) {
      const fail = MissingApiKeyFailure();
      _emit(_state.copyWith(errorMessage: fail.userMessage));
      return const Failure(fail);
    }

    final question = currentQuestion;
    if (question == null) return const Success(null);
    final choices = currentQuizChoices
        .map(
          (c) => PracticeChoice(
            label: c.label,
            content: c.content,
          ),
        )
        .toList();
    if (choices.isEmpty) return const Success(null);

    final tipRequestId = ++_quizTipRequestId;
    _emit(
      _state.copyWith(
        clearQuizTip: true,
        quizTipLoading: true,
        clearError: true,
      ),
    );

    final quotaFail = await _quota.consumeSolve(QuotaSolveKind.text);
    if (quotaFail != null) {
      if (_quizTipRequestId != tipRequestId) return const Success(null);
      _emit(
        _state.copyWith(
          quizTipLoading: false,
          errorMessage: quotaFail.userMessage,
        ),
      );
      return Failure(quotaFail);
    }

    final answered = _state.quizAnswered;
    final meaning = answered
        ? (_state.quizCorrectContent ??
                StudyNotesBuilder.answerMeaning(question, compact: false) ??
                '')
            .trim()
        : '';

    unawaited(
      _enrichQuizTip(
        question,
        choices,
        tipRequestId,
        // Spoil only after the user has already answered.
        answerMeaning: meaning,
        revealAnswer: answered,
      ),
    );
    return const Success(null);
  }

  bool _hasStoredAnswer(Question question) {
    final label = question.answerLabel?.trim();
    if (label != null && label.isNotEmpty) return true;
    final meaning = StudyNotesBuilder.answerMeaning(question, compact: false);
    return meaning != null && meaning.trim().isNotEmpty;
  }

  Future<QuizAnswerResolution?> _resolveAnswerWithLlm(
    Question question,
    List<PracticeChoice> choices,
  ) async {
    try {
      try {
        await _practice.prepareCredentials();
      } on Object catch (_) {}
      if (!await _practice.hasApiKey()) return null;

      final quotaFail = await _quota.consumeSolve(QuotaSolveKind.text);
      if (quotaFail != null) {
        _emit(_state.copyWith(errorMessage: quotaFail.userMessage));
        return null;
      }

      final stem = formatReviewQuestion(
        question,
        number: _state.displayNumber,
      );
      final resolved = await _deepSeek.resolveQuizAnswer(
        question: stem,
        choices: [
          for (final c in choices) (label: c.label, content: c.content),
        ],
      );
      _llmAnswers[question.id] = resolved;
      return resolved;
    } on Object catch (e) {
      _log.warning('Quiz answer resolve failed: ${e.runtimeType}');
      return null;
    }
  }

  /// Detailed heuristic tip; LLM upgrades it when activation is available.
  String _buildQuizTip(
    Question question,
    List<PracticeChoice> choices, {
    String answerMeaning = '',
  }) {
    final stem = formatReviewQuestion(
      question,
      number: _state.displayNumber,
    );
    final meaning = answerMeaning.isNotEmpty
        ? answerMeaning
        : (StudyNotesBuilder.answerMeaning(question, compact: false) ?? '');
    var tip = PracticeMcqTips.pickDetailed(
      question: stem,
      choices: choices.map((c) => c.display).toList(),
      context: meaning,
      correctAnswerMeaning: meaning,
      seed: _state.currentIndex + _state.completedCount,
    );
    tip = PracticeMcqTips.withoutQuestionEcho(tip, stem);
    tip = stripMcqChoiceLetters(tip);
    if (!tip.startsWith('Mẹo:') && !tip.startsWith('Mẹo :')) {
      tip = 'Mẹo: $tip';
    }
    return tip;
  }

  /// Build one detailed tip (LLM when possible, else heuristic) and show once.
  Future<void> _enrichQuizTip(
    Question question,
    List<PracticeChoice> choices,
    int tipRequestId, {
    String? answerMeaning,
    bool revealAnswer = false,
  }) async {
    Future<void> publish(String tip) async {
      if (_quizTipRequestId != tipRequestId) return;
      if (_state.stage != ReviewStage.running) return;
      if (_state.currentIndex >= _queue.length ||
          _queue[_state.currentIndex].id != question.id) {
        return;
      }
      _emit(_state.copyWith(quizTip: tip, quizTipLoading: false));
    }

    try {
      try {
        await _practice.prepareCredentials();
      } on Object catch (_) {}

      final stem = formatReviewQuestion(
        question,
        number: _state.displayNumber,
      );
      final meaning = revealAnswer
          ? (answerMeaning ??
              StudyNotesBuilder.answerMeaning(question, compact: false))
          : '';

      String tip;
      if (await _practice.hasApiKey()) {
        try {
          tip = await _deepSeek.generateMcqStrategyTip(
            question: stem,
            choices: choices.map((c) => c.display).toList(),
            correctAnswer: (meaning == null || meaning.trim().isEmpty)
                ? null
                : meaning,
          );
        } on Object catch (e) {
          _log.warning('Quiz tip LLM failed: ${e.runtimeType}');
          tip = _buildQuizTip(
            question,
            choices,
            answerMeaning: meaning ?? '',
          );
        }
      } else {
        tip = _buildQuizTip(
          question,
          choices,
          answerMeaning: meaning ?? '',
        );
      }

      tip = PracticeMcqTips.withoutQuestionEcho(tip, stem);
      tip = stripMcqChoiceLetters(tip);
      tip = tip.replaceAll(RegExp(r'\*\*|__'), '');
      if (!tip.startsWith('Mẹo:') && !tip.startsWith('Mẹo :')) {
        tip = 'Mẹo: $tip';
      }
      await publish(tip);
    } on Object catch (e) {
      _log.warning('Quiz tip failed: ${e.runtimeType}');
      final fallback = _buildQuizTip(
        question,
        choices,
        answerMeaning: revealAnswer ? (answerMeaning ?? '') : '',
      );
      await publish(fallback);
    }
  }

  /// Advance when the question has no choices (quiz mode).
  Result<void> skipQuizWithoutChoices() {
    if (_state.stage != ReviewStage.running ||
        _state.mode != ReviewPlayMode.quiz) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên giải đề.',
          code: 'review_inactive',
        ),
      );
    }
    _emit(
      _state.copyWith(
        quizAnswered: true,
        quizIsCorrect: null,
        clearError: true,
      ),
    );
    _markCurrentComplete();
    return const Success(null);
  }

  Future<void> cancel() async {
    _stopQuizCountdown();
    _practiceSub?.cancel();
    _practiceSub = null;
    await _practice.cancel();
    _queue = const [];
    _countedCurrent = false;
    _llmAnswers.clear();
    _emit(const ReviewSessionState(stage: ReviewStage.idle));
  }

  void finish() {
    _stopQuizCountdown();
    _practiceSub?.cancel();
    _practiceSub = null;
    _practice.reset();
    _queue = const [];
    _countedCurrent = false;
    _llmAnswers.clear();
    _emit(const ReviewSessionState(stage: ReviewStage.idle));
  }

  void dispose() {
    _stopQuizCountdown();
    _practiceSub?.cancel();
    _states.close();
  }

  Future<Result<void>> _startCurrent() async {
    final subjectId = _state.subjectId;
    if (subjectId == null || _queue.isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên ôn tập.',
          code: 'review_inactive',
        ),
      );
    }

    await _polishCurrentQuestionLatex();

    if (_state.mode == ReviewPlayMode.quiz) {
      // Local MCQ — auto-mark answered if no choices.
      if (currentQuizChoices.isEmpty) {
        skipQuizWithoutChoices();
      }
      return const Success(null);
    }

    final question = _queue[_state.currentIndex];
    final text = formatReviewQuestion(
      question,
      number: _state.displayNumber,
    );
    _countedCurrent = false;
    return _practice.startFromText(
      subjectId: subjectId,
      text: text,
      inputType: 'review_text',
      resultShortAnswer: 'Ôn tập',
      previewQuestionInChat: true,
      reviewMode: true,
      knownAnswerContent:
          StudyNotesBuilder.answerMeaning(question, compact: false),
    );
  }

  /// Heuristic enrich + optional LLM LaTeX polish; persists when improved.
  /// Skipped entirely for non-math subjects.
  Future<void> _polishCurrentQuestionLatex() async {
    final subjectId = _state.subjectId;
    if (subjectId == null || _queue.isEmpty) return;
    if (_formatKind != SubjectFormatKind.math) return;
    final index = _state.currentIndex;
    if (index < 0 || index >= _queue.length) return;

    var question = _queue[index];
    final local = _applyLocalLatexEnrich(question);
    final localChanged = local.content != question.content ||
        !_sameChoiceBodies(local.choices, question.choices) ||
        local.answerContent != question.answerContent;
    if (localChanged) {
      _replaceQueueQuestion(index, local);
      question = local;
      _emit(_state.copyWith(clearError: true));
      try {
        await _persistQuestionMath(
          subjectId: subjectId,
          questionId: local.id,
          content: local.content,
          choices: [
            for (final c in local.choices) (id: c.id, content: c.content),
          ],
          answerContent: local.answerContent,
        );
      } on Object catch (e) {
        _log.warning('Persist local LaTeX enrich failed: ${e.runtimeType}');
      }
    }

    final needsLlm = QuestionDisplayFormat.bundleNeedsLatexPolish(
      content: question.content,
      choiceContents: [for (final c in question.choices) c.content],
      answerContent: question.answerContent,
      kind: _formatKind,
    );
    if (!needsLlm) return;

    _emit(_state.copyWith(quizLatexLoading: true, clearError: true));
    try {
      try {
        await _practice.prepareCredentials();
      } on Object catch (_) {}
      if (!await _practice.hasApiKey()) {
        _emit(_state.copyWith(quizLatexLoading: false));
        return;
      }

      final formatted = await _deepSeek.formatMathLatex(
        content: question.content,
        choices: [
          for (final c in question.choices)
            (label: c.label, content: c.content),
        ],
        answerContent: question.answerContent,
        subjectName:
            _formatContext.name.isEmpty ? null : _formatContext.name,
        formatKind: _formatKind.wire,
      );

      if (_state.stage != ReviewStage.running ||
          _state.currentIndex != index) {
        return;
      }

      final polishedChoices = <QuestionChoice>[];
      for (var i = 0; i < question.choices.length; i++) {
        final original = question.choices[i];
        String body = original.content;
        if (i < formatted.choices.length) {
          body = QuestionDisplayFormat.enrich(
            formatted.choices[i].content,
            kind: _formatKind,
          );
        } else {
          body = QuestionDisplayFormat.enrich(body, kind: _formatKind);
        }
        polishedChoices.add(original.copyWith(content: body));
      }

      final polished = question.copyWith(
        content: QuestionDisplayFormat.enrich(
          formatted.content,
          kind: _formatKind,
        ),
        choices: polishedChoices,
        answerContent: formatted.answerContent == null
            ? question.answerContent
            : QuestionDisplayFormat.enrich(
                formatted.answerContent!,
                kind: _formatKind,
              ),
      );
      _replaceQueueQuestion(index, polished);
      try {
        await _persistQuestionMath(
          subjectId: subjectId,
          questionId: polished.id,
          content: polished.content,
          choices: [
            for (final c in polished.choices)
              (id: c.id, content: c.content),
          ],
          answerContent: polished.answerContent,
        );
      } on Object catch (e) {
        _log.warning('Persist LaTeX polish failed: ${e.runtimeType}');
      }
      _emit(_state.copyWith(quizLatexLoading: false, clearError: true));
    } on Object catch (e) {
      _log.warning('LLM LaTeX polish failed: ${e.runtimeType}');
      if (_state.stage == ReviewStage.running) {
        _emit(_state.copyWith(quizLatexLoading: false));
      }
    }
  }

  Question _applyLocalLatexEnrich(Question question) {
    return question.copyWith(
      content: QuestionDisplayFormat.enrich(
        question.content,
        kind: _formatKind,
      ),
      answerContent: question.answerContent == null
          ? null
          : QuestionDisplayFormat.enrich(
              question.answerContent!,
              kind: _formatKind,
            ),
      choices: [
        for (final c in question.choices)
          c.copyWith(
            content: QuestionDisplayFormat.enrich(
              c.content,
              kind: _formatKind,
            ),
          ),
      ],
    );
  }

  bool _sameChoiceBodies(List<QuestionChoice> a, List<QuestionChoice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].content != b[i].content) return false;
    }
    return true;
  }

  void _replaceQueueQuestion(int index, Question question) {
    if (index < 0 || index >= _queue.length) return;
    final next = [..._queue];
    next[index] = question;
    _queue = next;
  }

  void _watchPractice() {
    _practiceSub?.cancel();
    _practiceSub = _practice.states.listen((practice) {
      if (_state.stage != ReviewStage.running) return;
      if (_state.mode != ReviewPlayMode.coach) return;
      if (practice.stage == PracticeStage.completed) {
        _markCurrentComplete();
      } else if (practice.stage == PracticeStage.failed &&
          practice.errorMessage != null) {
        _emit(_state.copyWith(errorMessage: practice.errorMessage));
      }
    });
  }

  void _completeRun({bool timedOut = false}) {
    _stopQuizCountdown();
    _practiceSub?.cancel();
    _practiceSub = null;
    _practice.reset();
    final mode = _state.mode;
    final total = _state.total;
    final done = timedOut
        ? _state.completedCount.clamp(0, total)
        : total;
    final correct = _state.correctCount;
    final incorrect = _state.incorrectCount;
    _queue = const [];
    _countedCurrent = false;
    _emit(
      ReviewSessionState(
        stage: ReviewStage.completed,
        mode: mode,
        subjectId: _state.subjectId,
        total: total,
        completedCount: done,
        currentIndex: total > 0 ? total - 1 : 0,
        quizTimedOut: timedOut,
        quizRemaining: Duration.zero,
        correctCount: correct,
        incorrectCount: incorrect,
      ),
    );
  }

  void _startQuizCountdown() {
    _stopQuizCountdown();
    _quizEndsAt = DateTime.now().add(ReviewQuizConfig.duration);
    _emit(
      _state.copyWith(
        quizRemaining: ReviewQuizConfig.duration,
        quizTimedOut: false,
      ),
    );
    _quizTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final ends = _quizEndsAt;
      if (ends == null || _state.stage != ReviewStage.running) {
        _stopQuizCountdown();
        return;
      }
      final left = ends.difference(DateTime.now());
      if (left <= Duration.zero) {
        _emit(_state.copyWith(quizRemaining: Duration.zero));
        _completeRun(timedOut: true);
        return;
      }
      _emit(_state.copyWith(quizRemaining: left));
    });
  }

  void _stopQuizCountdown() {
    _quizTicker?.cancel();
    _quizTicker = null;
    _quizEndsAt = null;
  }

  void _markCurrentComplete() {
    if (_countedCurrent) return;
    _countedCurrent = true;
    final nextCount = (_state.currentIndex + 1).clamp(0, _state.total);
    if (nextCount != _state.completedCount) {
      _emit(_state.copyWith(completedCount: nextCount));
    }
    final subjectId = _state.subjectId;
    final question = currentQuestion;
    if (subjectId != null && question != null) {
      // Bump DB + in-memory counts so later duplicates in this run see the bump.
      unawaited(_recordPractice(subjectId, question.id));
    }
  }

  Future<void> _recordPractice(String subjectId, String questionId) async {
    try {
      await _incrementPracticeCount(
        subjectId: subjectId,
        questionId: questionId,
      );
      _bumpQueuePracticeCount(questionId);
    } on Object catch (e) {
      _log.warning('Increment practice count failed: ${e.runtimeType}');
    }
  }

  Future<void> _recordIncorrect(String subjectId, String questionId) async {
    try {
      await _incrementIncorrectCount(
        subjectId: subjectId,
        questionId: questionId,
      );
      _bumpQueueIncorrectCount(questionId);
    } on Object catch (e) {
      _log.warning('Increment incorrect count failed: ${e.runtimeType}');
    }
  }

  void _bumpQueuePracticeCount(String questionId) {
    var changed = false;
    final next = <Question>[];
    for (final q in _queue) {
      if (q.id == questionId) {
        next.add(q.copyWith(practiceCount: q.practiceCount + 1));
        changed = true;
      } else {
        next.add(q);
      }
    }
    if (changed) _queue = next;
  }

  void _bumpQueueIncorrectCount(String questionId) {
    var changed = false;
    final next = <Question>[];
    for (final q in _queue) {
      if (q.id == questionId) {
        next.add(q.copyWith(incorrectCount: q.incorrectCount + 1));
        changed = true;
      } else {
        next.add(q);
      }
    }
    if (changed) _queue = next;
  }

  void _emit(ReviewSessionState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}

final reviewServiceProvider = Provider<ReviewService>((ref) {
  final service = ReviewService(
    practice: ref.watch(practiceServiceProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
    quota: ref.watch(backendQuotaClientProvider),
    loadQuestions: (id) =>
        ref.read(subjectContentProvider).listQuestionsWithChoices(id),
    persistQuestionMath: ({
      required subjectId,
      required questionId,
      required content,
      choices = const [],
      answerContent,
    }) {
      return ref.read(subjectContentProvider).updateQuestionMath(
            subjectId: subjectId,
            questionId: questionId,
            content: content,
            choices: choices,
            answerContent: answerContent,
          );
    },
    incrementPracticeCount: ({
      required subjectId,
      required questionId,
    }) {
      return ref.read(subjectContentProvider).incrementPracticeCount(
            subjectId: subjectId,
            questionId: questionId,
          );
    },
    incrementIncorrectCount: ({
      required subjectId,
      required questionId,
    }) {
      return ref.read(subjectContentProvider).incrementIncorrectCount(
            subjectId: subjectId,
            questionId: questionId,
          );
    },
    resolveFormatKind: (id) async {
      final subject = await ref.read(subjectByIdProvider(id).future);
      return formatContextForSubject(subject);
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

final reviewStateProvider =
    StreamProvider.autoDispose<ReviewSessionState>((ref) {
  return ref.watch(reviewServiceProvider).states;
});
