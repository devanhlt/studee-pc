import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/features/practice/presentation/practice_chat_panel.dart';
import 'package:studee_pc/features/review/application/review_service.dart';
import 'package:studee_pc/features/review/application/review_quiz_config.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/features/settings/presentation/ensure_activation_code.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/subjects/application/study_notes_markdown_code.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

/// Ôn tập: quiz (Giải đề) or Socratic coach (Giải & luyện).
class ReviewPanel extends ConsumerWidget {
  const ReviewPanel({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewStateProvider).asData?.value ??
        ref.read(reviewServiceProvider).current;
    final questionsAsync = ref.watch(subjectQuestionsProvider(subjectId));

    return switch (review.stage) {
      ReviewStage.idle => _IdleReview(
          subjectId: subjectId,
          questionsAsync: questionsAsync,
          errorMessage: review.errorMessage,
        ),
      ReviewStage.completed => _CompletedReview(
          subjectId: subjectId,
          review: review,
        ),
      ReviewStage.running => _RunningReview(mode: review.mode),
    };
  }
}

class _IdleReview extends ConsumerWidget {
  const _IdleReview({
    required this.subjectId,
    required this.questionsAsync,
    this.errorMessage,
  });

  final String subjectId;
  final AsyncValue<List<Question>> questionsAsync;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return questionsAsync.when(
      loading: () => const StudeeSkeletonList(),
      error: (_, _) => const StudeeStatusState(
        icon: AppIcons.error,
        title: 'Không tải được câu hỏi',
        message: 'Thử mở lại môn học hoặc nhập thêm tài liệu.',
      ),
      data: (questions) {
        final count =
            questions.where((q) => q.content.trim().isNotEmpty).length;
        if (count == 0) {
          return const StudeeStatusState(
            icon: AppIcons.review,
            title: 'Chưa có câu hỏi để ôn',
            message:
                'Hãy nhập tài liệu ở Kiến thức trước, rồi quay lại ôn tập.',
          );
        }
        return Padding(
          padding: AppLayout.pageInsets(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudeeSectionLabel(
                      'Ôn tập giải đề với Stud',
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppLayout.gapSm),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppLayout.gapMd),
                    const _ReviewDurationPicker(),
                    const SizedBox(height: AppLayout.gapMd),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 420;
                        final coach = FilledButton.icon(
                          onPressed: () => startReviewSession(
                            context,
                            ref,
                            subjectId,
                            mode: ReviewPlayMode.coach,
                          ),
                          icon: const Icon(AppIcons.review),
                          label: const Text('Giải & luyện'),
                        );
                        final quiz = OutlinedButton.icon(
                          onPressed: () => startReviewSession(
                            context,
                            ref,
                            subjectId,
                            mode: ReviewPlayMode.quiz,
                          ),
                          icon: const Icon(AppIcons.checkCircle),
                          label: const Text('Giải đề'),
                        );
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              coach,
                              const SizedBox(height: AppLayout.gapSm),
                              quiz,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: coach),
                            const SizedBox(width: AppLayout.gapSm),
                            Expanded(child: quiz),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewDurationPicker extends ConsumerWidget {
  const _ReviewDurationPicker();

  Future<void> _setMinutes(WidgetRef ref, int minutes) async {
    await ref.read(reviewQuizSettingsStoreProvider).setDurationMinutes(minutes);
    ref.invalidate(reviewQuizDurationMinutesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMinutes = ref.watch(reviewQuizDurationMinutesProvider);
    final theme = Theme.of(context).textTheme;
    final selected = asyncMinutes.asData?.value ??
        ReviewQuizConfig.defaultDurationMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thời gian: $selected phút',
          style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppLayout.gapXs),
        Text(
          'Áp dụng cho Giải đề và Giải & luyện.',
          style: theme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppLayout.gapSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutes in ReviewQuizConfig.durationMinutePresets)
              ChoiceChip(
                label: Text('$minutes phút'),
                selected: selected == minutes,
                onSelected: (_) => _setMinutes(ref, minutes),
              ),
          ],
        ),
      ],
    );
  }
}

class _CompletedReview extends ConsumerWidget {
  const _CompletedReview({
    required this.subjectId,
    required this.review,
  });

  final String subjectId;
  final ReviewSessionState review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = review.mode;
    final timedOut = review.quizTimedOut;
    final total = review.total;
    final completedCount = review.completedCount;
    final againLabel =
        mode == ReviewPlayMode.quiz ? 'Giải đề lại' : 'Luyện lại từ đầu';
    final title = timedOut
        ? 'Hết giờ'
        : (mode == ReviewPlayMode.quiz
            ? 'Đã làm xong $total câu'
            : 'Đã ôn xong $total câu');
    final showQuizStats = mode == ReviewPlayMode.quiz;
    final accuracy = review.accuracy;
    final accuracyLabel = accuracy == null
        ? '—'
        : '${(accuracy * 100).round()}%';

    return Center(
      child: SingleChildScrollView(
        padding: AppLayout.pageInsets(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              timedOut ? AppIcons.timer : AppIcons.checkCircle,
              size: AppIcons.sizeEmptyState,
              color: AppColors.accent.withValues(alpha: 0.85),
            ),
            const SizedBox(height: AppLayout.gapMd),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppLayout.gapSm),
            Text(
              timedOut
                  ? 'Hết ${review.quizLimit.inMinutes} phút. '
                      'Bạn đã làm $completedCount/$total câu.'
                  : 'Bạn có thể ôn lại từ đầu, hoặc chuyển sang Luyện / Giải.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
            if (showQuizStats) ...[
              const SizedBox(height: AppLayout.gapLg),
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kết quả',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppLayout.gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultStat(
                            label: 'Đúng',
                            value: '${review.correctCount}',
                            color: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _ResultStat(
                            label: 'Sai',
                            value: '${review.incorrectCount}',
                            color: AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _ResultStat(
                            label: timedOut ? 'Chưa làm' : 'Đã làm',
                            value: timedOut
                                ? '${review.unansweredCount}'
                                : '${review.answeredCount}/$total',
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.gapMd),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tỷ lệ đúng',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            accuracyLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppLayout.gapLg),
            FilledButton(
              onPressed: () => startReviewSession(
                context,
                ref,
                subjectId,
                mode: mode,
              ),
              child: Text(againLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RunningReview extends ConsumerWidget {
  const _RunningReview({required this.mode});

  final ReviewPlayMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == ReviewPlayMode.quiz) {
      return const _RunningQuizReview();
    }
    return const _RunningCoachReview();
  }
}

class _RunningCoachReview extends ConsumerWidget {
  const _RunningCoachReview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewStateProvider).asData?.value ??
        ref.read(reviewServiceProvider).current;
    final practice = ref.watch(practiceStateProvider).asData?.value ??
        ref.read(practiceServiceProvider).current;
    final failed = practice.stage == PracticeStage.failed;
    final lastDone =
        review.isLastQuestion && practice.stage == PracticeStage.completed;

    return Padding(
      padding: const EdgeInsets.all(AppLayout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReviewProgressHeader(review: review),
          const SizedBox(height: AppLayout.gapSm),
          Expanded(
            child: PracticeChatPanel(
              showCancelAlways: false,
              completedMessage: lastDone
                  ? 'Đã ôn xong tất cả câu hỏi.'
                  : 'Đã xong câu này. Bấm “Câu tiếp” để ôn câu sau.',
              completedComposerHint: lastDone
                  ? 'Đã ôn xong tất cả câu hỏi'
                  : 'Đã xong câu này',
              nextQuestionLabel: failed
                  ? 'Thử lại'
                  : (lastDone ? 'Xong' : 'Câu tiếp'),
              onCancel: () => confirmCancelReviewSession(context, ref),
              onNewQuestion: () {
                final service = ref.read(reviewServiceProvider);
                if (failed) {
                  service.retryCurrent();
                  return;
                }
                service.continueNext();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningQuizReview extends ConsumerStatefulWidget {
  const _RunningQuizReview();

  @override
  ConsumerState<_RunningQuizReview> createState() => _RunningQuizReviewState();
}

class _RunningQuizReviewState extends ConsumerState<_RunningQuizReview> {
  final _scrollController = ScrollController();
  int? _seenIndex;
  Timer? _autoNextTimer;
  /// Remaining fraction 1→0 while auto-advance is counting down.
  double? _autoNextProgress;
  /// Set when the user opens Gợi ý so auto-advance does not restart.
  bool _autoNextSuppressed = false;

  bool _canAdvance(ReviewSessionState review, List<QuestionChoice> choices) {
    if (review.quizResolvingAnswer) return false;
    return review.quizAnswered || choices.isEmpty;
  }

  void _clearAutoNextTimer() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    _autoNextProgress = null;
  }

  void _stopAutoNext({bool suppress = false}) {
    _clearAutoNextTimer();
    if (suppress) _autoNextSuppressed = true;
  }

  void _startAutoNext() {
    if (_autoNextSuppressed || _autoNextTimer != null) return;
    final totalMs = ReviewQuizConfig.autoAdvanceDelay.inMilliseconds;
    if (totalMs <= 0) {
      _goNext();
      return;
    }
    final endsAt = DateTime.now().add(ReviewQuizConfig.autoAdvanceDelay);
    _autoNextProgress = 1.0;
    _autoNextTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final leftMs = endsAt.difference(DateTime.now()).inMilliseconds;
      if (leftMs <= 0) {
        timer.cancel();
        _autoNextTimer = null;
        _autoNextProgress = null;
        _goNext();
        return;
      }
      setState(() {
        _autoNextProgress = (leftMs / totalMs).clamp(0.0, 1.0);
      });
    });
    setState(() {});
  }

  void _syncAutoNext({required bool canAdvance}) {
    if (!canAdvance || _autoNextSuppressed) {
      if (_autoNextTimer != null || _autoNextProgress != null) {
        _clearAutoNextTimer();
        if (mounted) setState(() {});
      }
      return;
    }
    if (_autoNextTimer == null) _startAutoNext();
  }

  void _goNext() {
    _clearAutoNextTimer();
    final service = ref.read(reviewServiceProvider);
    final review = service.current;
    final choices = service.currentQuizChoices;
    if (!_canAdvance(review, choices)) {
      if (mounted) setState(() {});
      return;
    }
    if (!review.quizAnswered && choices.isEmpty) {
      service.skipQuizWithoutChoices();
    }
    service.continueNext();
    if (mounted) setState(() {});
  }

  Future<void> _onRequestTip() async {
    _stopAutoNext(suppress: true);
    if (mounted) setState(() {});
    await _requestQuizTip(
      context,
      ref,
      ref.read(reviewServiceProvider),
    );
  }

  @override
  void dispose() {
    _clearAutoNextTimer();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToQuestionTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(reviewServiceProvider);
    final review = ref.watch(reviewStateProvider).asData?.value ?? service.current;
    final question = service.currentQuestion;
    final choices = service.currentQuizChoices;
    final lastDone = review.isLastQuestion && review.quizAnswered;
    final canAdvance = _canAdvance(review, choices);
    final subjectId = review.subjectId;
    final subject = subjectId == null
        ? null
        : ref.watch(subjectByIdProvider(subjectId)).asData?.value;
    final formatKind = formatKindForSubject(subject);

    if (_seenIndex != review.currentIndex) {
      _seenIndex = review.currentIndex;
      _autoNextSuppressed = false;
      _clearAutoNextTimer();
      _scrollToQuestionTop();
    }

    ref.listen(reviewStateProvider, (prev, next) {
      final prevReview = prev?.asData?.value;
      final nextReview = next.asData?.value;
      if (nextReview == null) return;

      final msg = nextReview.errorMessage;
      final prevMsg = prevReview?.errorMessage;
      if (msg != null && msg.isNotEmpty && msg != prevMsg) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          if (isMissingActivationMessage(msg)) {
            context.push('/settings');
          }
        }
      }

      final choicesNow =
          ref.read(reviewServiceProvider).currentQuizChoices;
      final canAdvanceNow = _canAdvance(nextReview, choicesNow);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncAutoNext(canAdvance: canAdvanceNow);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAutoNext(canAdvance: canAdvance);
    });

    final autoNextProgress = _autoNextProgress;

    return Padding(
      padding: const EdgeInsets.all(AppLayout.cardPadding),
      child: question == null
          ? const Center(child: Text('Không có câu hỏi.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReviewProgressHeader(review: review),
                const SizedBox(height: AppLayout.gapSm),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 64),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (review.quizLatexLoading) ...[
                                const SizedBox(height: AppLayout.gapSm),
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Đang chuẩn hóa công thức…',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppLayout.gapSm),
                              ],
                              StudyMarkdown(
                                StudyNotesMarkdownCode.formatBody(
                                  question.content.trim(),
                                  kind: formatKind,
                                ),
                                formatKind: formatKind,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primaryText,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: AppLayout.gapMd),
                              if (choices.isEmpty)
                                const Text(
                                  'Câu này chưa có đáp án lựa chọn đã lưu.',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                )
                              else
                                ...choices.map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppLayout.gapSm,
                                    ),
                                    child: _QuizChoiceButton(
                                      choice: c,
                                      formatKind: formatKind,
                                      selectedLabel: review.quizSelectedLabel,
                                      answered: review.quizAnswered,
                                      isCorrectPick: review.quizIsCorrect,
                                      correctLabel: review.quizCorrectLabel ??
                                          question.answerLabel?.trim(),
                                      onTap: (review.quizAnswered ||
                                              review.quizResolvingAnswer)
                                          ? null
                                          : () =>
                                              service.submitQuizChoice(c),
                                    ),
                                  ),
                                ),
                              if (!review.quizResolvingAnswer &&
                                  choices.isNotEmpty &&
                                  !review.quizTipLoading &&
                                  (review.quizTip == null ||
                                      review.quizTip!.trim().isEmpty)) ...[
                                const SizedBox(height: AppLayout.gapMd),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: _onRequestTip,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: const BorderSide(
                                        color: AppColors.accent,
                                        width: 1.5,
                                      ),
                                    ),
                                    icon: const Icon(
                                      AppIcons.sparkle,
                                      size: 18,
                                    ),
                                    label: const Text('Gợi ý'),
                                  ),
                                ),
                              ],
                              if (review.quizTipLoading ||
                                  (review.quizTip != null &&
                                      review.quizTip!
                                          .trim()
                                          .isNotEmpty)) ...[
                                const SizedBox(height: AppLayout.gapMd),
                                _QuizTipCard(
                                  tip: review.quizTip,
                                  loading: review.quizTipLoading,
                                  formatKind: formatKind,
                                ),
                              ],
                              if (review.quizResolvingAnswer) ...[
                                const SizedBox(height: AppLayout.gapMd),
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Đề chưa có đáp án lưu — Stud đang suy luận…',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (canAdvance)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _QuizAutoNextFab(
                            isLast: lastDone ||
                                (review.isLastQuestion && choices.isEmpty),
                            progress: autoNextProgress,
                            onPressed: _goNext,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuizAutoNextFab extends StatelessWidget {
  const _QuizAutoNextFab({
    required this.isLast,
    required this.onPressed,
    this.progress,
  });

  final bool isLast;
  final VoidCallback onPressed;
  /// Remaining countdown fraction (1 → 0). Null = no ring.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final icon = isLast ? AppIcons.checkCircle : AppIcons.chevronRight;
    final tooltip = isLast ? 'Xong' : 'Câu tiếp';
    final remaining = progress;

    Widget button = Material(
      color: AppColors.accent,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );

    if (remaining != null) {
      button = SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: remaining.clamp(0.0, 1.0),
                strokeWidth: 2.5,
                backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                color: AppColors.accent,
              ),
            ),
            button,
          ],
        ),
      );
    }

    return Tooltip(message: tooltip, child: button);
  }
}

class _ReviewProgressHeader extends ConsumerWidget {
  const _ReviewProgressHeader({required this.review});

  final ReviewSessionState review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTimer = review.stage == ReviewStage.running;
    final remaining = review.quizRemaining;
    final urgent = remaining.inMinutes < 5;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Câu ${review.displayNumber} / ${review.total}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.1,
              ),
            ),
          ),
          if (showTimer) ...[
            Icon(
              AppIcons.timer,
              size: 13,
              color: urgent ? AppColors.error : AppColors.secondaryText,
            ),
            const SizedBox(width: 3),
            Text(
              formatQuizCountdown(remaining),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: urgent ? AppColors.error : AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 2),
          ],
          TextButton(
            onPressed: () => confirmCancelReviewSession(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _QuizChoiceButton extends StatelessWidget {
  const _QuizChoiceButton({
    required this.choice,
    required this.formatKind,
    required this.selectedLabel,
    required this.answered,
    required this.isCorrectPick,
    required this.correctLabel,
    required this.onTap,
  });

  final QuestionChoice choice;
  final SubjectFormatKind formatKind;
  final String? selectedLabel;
  final bool answered;
  final bool? isCorrectPick;
  final String? correctLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = choice.label.trim().toUpperCase();
    final selected =
        selectedLabel != null && selectedLabel!.toUpperCase() == label;
    final isKey = correctLabel != null &&
        correctLabel!.toUpperCase() == label;

    Color? border;
    Color? fill;
    if (answered) {
      if (isKey) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.12);
      } else if (selected && isCorrectPick == false) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.10);
      }
    } else if (selected) {
      border = AppColors.accent;
      fill = AppColors.accent.withValues(alpha: 0.10);
    }

    final bodyRaw = choice.content.trim();
    final isCode =
        StudyNotesMarkdownCode.isCodeSnippet(bodyRaw, kind: formatKind);
    final body = isCode
        ? StudyNotesMarkdownCode.codeSnippetBody(bodyRaw)
        : StudyNotesMarkdownCode.formatBody(bodyRaw, kind: formatKind);

    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border ?? AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty) ...[
                Text(
                  '$label.',
                  style: const TextStyle(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: isCode
                    ? _QuizCodeSnippet(code: body)
                    : StudyMarkdown(
                        body,
                        compact: true,
                        formatKind: formatKind,
                        style: const TextStyle(
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryText,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCodeSnippet extends StatelessWidget {
  const _QuizCodeSnippet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'Menlo',
          fontFamilyFallback: ['monospace', 'Courier'],
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class _QuizTipCard extends StatelessWidget {
  const _QuizTipCard({
    this.tip,
    this.loading = false,
    this.formatKind = SubjectFormatKind.plain,
  });

  final String? tip;
  final bool loading;
  final SubjectFormatKind formatKind;

  @override
  Widget build(BuildContext context) {
    final body = tip?.trim() ?? '';
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryText,
          height: 1.45,
          fontWeight: FontWeight.w400,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (body.isNotEmpty)
            StudyMarkdown(
              body,
              compact: true,
              formatKind: formatKind,
              style: baseStyle,
            ),
          if (loading) ...[
            if (body.isNotEmpty) const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang phân tích…',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _requestQuizTip(
  BuildContext context,
  WidgetRef ref,
  ReviewService service,
) async {
  final practice = ref.read(practiceServiceProvider);
  try {
    await practice.prepareCredentials();
  } on Object catch (_) {}
  if (!context.mounted) return;
  if (!await ensureActivationCode(
    context,
    hasCode: practice.hasApiKey,
  )) {
    return;
  }
  if (!context.mounted) return;
  await service.requestQuizTip();
}

Future<bool> confirmCancelReviewSession(
  BuildContext context,
  WidgetRef ref,
) async {
  final review = ref.read(reviewServiceProvider).current;
  if (review.stage != ReviewStage.running) {
    await ref.read(reviewServiceProvider).cancel();
    return true;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hủy ôn tập?'),
      content: const Text(
        'Tiến trình ôn tập hiện tại sẽ bị hủy. Không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Ở lại'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hủy ôn tập'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await ref.read(reviewServiceProvider).cancel();
  return true;
}

Future<void> startReviewSession(
  BuildContext context,
  WidgetRef ref,
  String subjectId, {
  ReviewPlayMode mode = ReviewPlayMode.coach,
}) async {
  if (mode == ReviewPlayMode.coach) {
    final practice = ref.read(practiceServiceProvider);
    try {
      await practice.prepareCredentials();
    } on Object catch (_) {}
    if (!context.mounted) return;
    if (!await ensureActivationCode(
      context,
      hasCode: practice.hasApiKey,
    )) {
      return;
    }
    if (!context.mounted) return;
    final ok = await ensureDeepSeekPrivacyConsent(
      context,
      store: ref.read(privacyConsentStoreProvider),
    );
    if (!ok || !context.mounted) return;
  }

  final durationMinutes = await ref
      .read(reviewQuizSettingsStoreProvider)
      .loadDurationMinutes();
  if (!context.mounted) return;

  final result = await ref.read(reviewServiceProvider).start(
        subjectId,
        mode: mode,
        duration: ReviewQuizConfig.durationFromMinutes(
          ReviewQuizConfig.snapDurationMinutes(durationMinutes),
        ),
      );
  if (!context.mounted) return;
  result.when(
    success: (_) {},
    failure: (f) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.userMessage)),
      );
      if (f is MissingApiKeyFailure ||
          isMissingActivationMessage(f.userMessage)) {
        context.push('/settings');
      }
    },
  );
}
