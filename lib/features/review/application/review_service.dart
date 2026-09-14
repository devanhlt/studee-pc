import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/features/review/application/review_question_text.dart';
import 'package:studee_pc/features/subjects/application/study_notes_builder.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

enum ReviewStage { idle, running, completed }

class ReviewSessionState {
  const ReviewSessionState({
    required this.stage,
    this.subjectId,
    this.total = 0,
    this.currentIndex = 0,
    this.completedCount = 0,
    this.errorMessage,
  });

  final ReviewStage stage;
  final String? subjectId;
  final int total;
  final int currentIndex;
  final int completedCount;
  final String? errorMessage;

  bool get isIncomplete => stage == ReviewStage.running;

  bool get isLastQuestion => total > 0 && currentIndex >= total - 1;

  int get displayNumber => total == 0 ? 0 : currentIndex + 1;

  double get progress {
    if (total <= 0) return 0;
    return (completedCount / total).clamp(0.0, 1.0);
  }

  ReviewSessionState copyWith({
    ReviewStage? stage,
    String? subjectId,
    int? total,
    int? currentIndex,
    int? completedCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReviewSessionState(
      stage: stage ?? this.stage,
      subjectId: subjectId ?? this.subjectId,
      total: total ?? this.total,
      currentIndex: currentIndex ?? this.currentIndex,
      completedCount: completedCount ?? this.completedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Walks every saved question with the same Socratic coach as Luyện.
///
/// Each started question charges text tokens once.
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

  Future<Result<void>> start(String subjectId) async {
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
    _watchPractice();
    _emit(
      ReviewSessionState(
        stage: ReviewStage.running,
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
    if (_practice.current.stage != PracticeStage.completed) {
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
    return _startCurrent();
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
      previewQuestionInChat: false,
      reviewMode: true,
      knownAnswerContent:
          StudyNotesBuilder.answerMeaning(question, compact: false),
    );
  }

  void _watchPractice() {
    _practiceSub?.cancel();
    _practiceSub = _practice.states.listen((practice) {
      if (_state.stage != ReviewStage.running) return;
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
    _queue = const [];
    _countedCurrent = false;
    _emit(
      _state.copyWith(
        stage: ReviewStage.completed,
        completedCount: _state.total,
        clearError: true,
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
