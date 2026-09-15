import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_grade.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_tips.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/features/review/application/review_answer_style.dart';
import 'package:studee_pc/features/review/application/review_question_text.dart';
import 'package:studee_pc/features/subjects/application/study_notes_builder.dart';
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

  bool get isIncomplete => stage == ReviewStage.running;

  bool get isLastQuestion => total > 0 && currentIndex >= total - 1;

  int get displayNumber => total == 0 ? 0 : currentIndex + 1;

  double get progress {
    if (total <= 0) return 0;
    return (completedCount / total).clamp(0.0, 1.0);
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
    bool clearQuiz = false,
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
      quizTip: clearQuiz ? null : (quizTip ?? this.quizTip),
    );
  }
}

/// Walks every saved question — either MCQ quiz or Socratic coach.
class ReviewService {
  ReviewService({
    required PracticeService practice,
    required Future<List<Question>> Function(String subjectId) loadQuestions,
  })  : _practice = practice,
        _loadQuestions = loadQuestions;

  final PracticeService _practice;
  final Future<List<Question>> Function(String subjectId) _loadQuestions;
  final AppLogger _log = AppLogger('ReviewService');

  final StreamController<ReviewSessionState> _states =
      StreamController<ReviewSessionState>.broadcast();

  ReviewSessionState _state = const ReviewSessionState(stage: ReviewStage.idle);
  List<Question> _queue = const [];
  bool _countedCurrent = false;
  StreamSubscription<PracticeSessionState>? _practiceSub;

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

    _queue = questions;
    _countedCurrent = false;
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
        total: questions.length,
        currentIndex: 0,
        completedCount: 0,
      ),
    );
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
  Result<void> submitQuizChoice(QuestionChoice choice) {
    if (_state.stage != ReviewStage.running ||
        _state.mode != ReviewPlayMode.quiz) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Chưa có phiên giải đề.',
          code: 'review_inactive',
        ),
      );
    }
    if (_state.quizAnswered) return const Success(null);

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
    final correctLabel = question.answerLabel?.trim();
    var isCorrect = PracticeMcqGrade.grade(
      answer: choice.label.isNotEmpty
          ? '${choice.label}. ${choice.content}'.trim()
          : choice.content,
      correctLabel: correctLabel,
      choices: choices,
    );

    // Fallback: match by answer content / meaning when label missing.
    if (isCorrect == null) {
      final meaning = StudyNotesBuilder.answerMeaning(question, compact: false)
          ?.trim()
          .toLowerCase();
      final picked = choice.content.trim().toLowerCase();
      if (meaning != null && meaning.isNotEmpty && picked.isNotEmpty) {
        isCorrect = picked == meaning ||
            meaning.contains(picked) ||
            picked.contains(meaning);
      }
    }

    final tip = _buildQuizTip(question, choices);

    _emit(
      _state.copyWith(
        quizSelectedLabel: choice.label,
        quizIsCorrect: isCorrect ?? false,
        quizAnswered: true,
        quizTip: tip,
        clearError: true,
      ),
    );
    _markCurrentComplete();
    return const Success(null);
  }

  /// Same tip rules as Luyện's final `mcq_tip` fallback (heuristic + "Mẹo:").
  String _buildQuizTip(Question question, List<PracticeChoice> choices) {
    final stem = formatReviewQuestion(
      question,
      number: _state.displayNumber,
    );
    final answerMeaning =
        StudyNotesBuilder.answerMeaning(question, compact: false) ?? '';
    var tip = PracticeMcqTips.pick(
      question: stem,
      choices: choices.map((c) => c.display).toList(),
      context: answerMeaning,
      seed: _state.currentIndex + _state.completedCount,
    );
    tip = stripMcqChoiceLetters(tip);
    if (!tip.startsWith('Mẹo:') && !tip.startsWith('Mẹo :')) {
      tip = 'Mẹo: $tip';
    }
    return tip;
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
    _practiceSub?.cancel();
    _practiceSub = null;
    await _practice.cancel();
    _queue = const [];
    _countedCurrent = false;
    _emit(const ReviewSessionState(stage: ReviewStage.idle));
  }

  void finish() {
    _practiceSub?.cancel();
    _practiceSub = null;
    _practice.reset();
    _queue = const [];
    _countedCurrent = false;
    _emit(const ReviewSessionState(stage: ReviewStage.idle));
  }

  void dispose() {
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

    if (_state.mode == ReviewPlayMode.quiz) {
      // Local MCQ — no API call. Auto-mark answered if no choices.
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

  void _completeRun() {
    _practiceSub?.cancel();
    _practiceSub = null;
    _practice.reset();
    final mode = _state.mode;
    final total = _state.total;
    _queue = const [];
    _countedCurrent = false;
    _emit(
      ReviewSessionState(
        stage: ReviewStage.completed,
        mode: mode,
        total: total,
        completedCount: total,
        currentIndex: total > 0 ? total - 1 : 0,
      ),
    );
  }

  void _markCurrentComplete() {
    if (_countedCurrent) return;
    _countedCurrent = true;
    final nextCount = (_state.currentIndex + 1).clamp(0, _state.total);
    if (nextCount != _state.completedCount) {
      _emit(_state.copyWith(completedCount: nextCount));
    }
  }

  void _emit(ReviewSessionState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}

final reviewServiceProvider = Provider<ReviewService>((ref) {
  final service = ReviewService(
    practice: ref.watch(practiceServiceProvider),
    loadQuestions: (id) =>
        ref.read(subjectContentProvider).listQuestionsWithChoices(id),
  );
  ref.onDispose(service.dispose);
  return service;
});

final reviewStateProvider =
    StreamProvider.autoDispose<ReviewSessionState>((ref) {
  return ref.watch(reviewServiceProvider).states;
});
