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
          total: review.total,
          mode: review.mode,
          completedCount: review.completedCount,
          timedOut: review.quizTimedOut,
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

class _CompletedReview extends ConsumerWidget {
  const _CompletedReview({
    required this.subjectId,
    required this.total,
    required this.mode,
    required this.completedCount,
    required this.timedOut,
  });

  final String subjectId;
  final int total;
  final ReviewPlayMode mode;
  final int completedCount;
  final bool timedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final againLabel =
        mode == ReviewPlayMode.quiz ? 'Giải đề lại' : 'Luyện lại từ đầu';
    final title = timedOut
        ? 'Hết giờ'
        : (mode == ReviewPlayMode.quiz
            ? 'Đã làm xong $total câu'
            : 'Đã ôn xong $total câu');
    final message = timedOut
        ? 'Hết ${ReviewQuizConfig.duration.inMinutes} phút. '
            'Bạn đã làm $completedCount/$total câu. Có thể giải đề lại bất cứ lúc nào.'
        : 'Bạn có thể ôn lại từ đầu, hoặc chuyển sang Luyện / Giải.';
    return StudeeStatusState(
      icon: timedOut ? AppIcons.timer : AppIcons.checkCircle,
      title: title,
      message: message,
      actionLabel: againLabel,
      onAction: () => startReviewSession(
        context,
        ref,
        subjectId,
        mode: mode,
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewProgressHeader(review: review),
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
            onCancel: () => ref.read(reviewServiceProvider).cancel(),
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
    );
  }
}

class _RunningQuizReview extends ConsumerWidget {
  const _RunningQuizReview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(reviewServiceProvider);
    final review = ref.watch(reviewStateProvider).asData?.value ?? service.current;
    final question = service.currentQuestion;
    final choices = service.currentQuizChoices;
    final lastDone = review.isLastQuestion && review.quizAnswered;
    final subjectId = review.subjectId;
    final subject = subjectId == null
        ? null
        : ref.watch(subjectByIdProvider(subjectId)).asData?.value;
    final formatKind = formatKindForSubject(subject);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewProgressHeader(review: review),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pagePadding,
              0,
              AppLayout.pagePadding,
              AppLayout.pagePadding,
            ),
            child: StudeeGlass(
              padding: const EdgeInsets.all(AppLayout.cardPadding),
              child: question == null
                  ? const Center(child: Text('Không có câu hỏi.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
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
                                            : () => service
                                                .submitQuizChoice(c),
                                      ),
                                    ),
                                  ),
                                if (!review.quizAnswered &&
                                    !review.quizResolvingAnswer &&
                                    choices.isNotEmpty &&
                                    !review.quizTipLoading &&
                                    (review.quizTip == null ||
                                        review.quizTip!.trim().isEmpty)) ...[
                                  const SizedBox(height: AppLayout.gapMd),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          service.requestQuizTip(),
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
                                if (review.quizAnswered) ...[
                                  const SizedBox(height: AppLayout.gapSm),
                                  _QuizFeedback(
                                    isCorrect: review.quizIsCorrect,
                                    correctLabel: review.quizCorrectLabel ??
                                        question.answerLabel?.trim(),
                                    correctContent: review.quizCorrectContent,
                                    fromLlm: review.quizAnswerFromLlm,
                                    choices: choices,
                                    formatKind: formatKind,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppLayout.gapMd),
                        FilledButton(
                          onPressed: (!review.quizAnswered &&
                                      choices.isNotEmpty) ||
                                  review.quizResolvingAnswer
                              ? null
                              : () {
                                  if (!review.quizAnswered &&
                                      choices.isEmpty) {
                                    service.skipQuizWithoutChoices();
                                  }
                                  service.continueNext();
                                },
                          child: Text(
                            !review.quizAnswered && choices.isEmpty
                                ? (review.isLastQuestion
                                    ? 'Bỏ qua & xong'
                                    : 'Bỏ qua & câu tiếp')
                                : (lastDone ? 'Xong' : 'Câu tiếp'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.pagePadding,
        0,
        AppLayout.pagePadding,
        AppLayout.gapSm,
      ),
      child: StudeeGlass(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Câu ${review.displayNumber} / ${review.total}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showTimer) ...[
                  Icon(
                    AppIcons.timer,
                    size: 16,
                    color: urgent ? AppColors.error : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatQuizCountdown(remaining),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: urgent ? AppColors.error : AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => ref.read(reviewServiceProvider).cancel(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Hủy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StudeeGradientProgress(value: review.progress),
          ],
        ),
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

class _QuizFeedback extends StatelessWidget {
  const _QuizFeedback({
    required this.isCorrect,
    required this.correctLabel,
    required this.choices,
    this.correctContent,
    this.fromLlm = false,
    this.formatKind = SubjectFormatKind.plain,
  });

  final bool? isCorrect;
  final String? correctLabel;
  final String? correctContent;
  final bool fromLlm;
  final List<QuestionChoice> choices;
  final SubjectFormatKind formatKind;

  @override
  Widget build(BuildContext context) {
    if (isCorrect == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chính xác!',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (fromLlm)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Đáp án do Stud suy luận (đề chưa có đáp án lưu).',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      );
    }

    Widget? answerBody;
    String? answerLabel;
    if (correctLabel != null && correctLabel!.isNotEmpty) {
      for (final c in choices) {
        if (c.label.trim().toUpperCase() == correctLabel!.toUpperCase()) {
          answerLabel = c.label.trim().toUpperCase();
          final raw = c.content.trim();
          if (StudyNotesMarkdownCode.isCodeSnippet(raw, kind: formatKind)) {
            answerBody = _QuizCodeSnippet(
              code: StudyNotesMarkdownCode.codeSnippetBody(raw),
            );
          } else {
            answerBody = StudyMarkdown(
              StudyNotesMarkdownCode.formatBody(raw, kind: formatKind),
              compact: true,
              formatKind: formatKind,
            );
          }
          break;
        }
      }
    }
    if (answerBody == null &&
        correctContent != null &&
        correctContent!.trim().isNotEmpty) {
      answerLabel = correctLabel?.trim();
      final raw = correctContent!.trim();
      if (StudyNotesMarkdownCode.isCodeSnippet(raw, kind: formatKind)) {
        answerBody = _QuizCodeSnippet(
          code: StudyNotesMarkdownCode.codeSnippetBody(raw),
        );
      } else {
        answerBody = StudyMarkdown(
          StudyNotesMarkdownCode.formatBody(raw, kind: formatKind),
          compact: true,
          formatKind: formatKind,
        );
      }
    }
    if (answerBody == null && correctLabel != null) {
      answerBody = Text(correctLabel!);
    }

    if (answerBody == null) {
      return Text(
        fromLlm
            ? 'Chưa đúng. Stud chưa suy ra được đáp án.'
            : 'Chưa đúng.',
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chưa đúng. Đáp án:',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (answerLabel != null && answerLabel.isNotEmpty) ...[
              Text(
                '$answerLabel.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: answerBody),
          ],
        ),
        if (fromLlm)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Đáp án do Stud suy luận (đề chưa có đáp án lưu).',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
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
    if (!await practice.hasApiKey()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.'),
        ),
      );
      context.push('/settings');
      return;
    }
    if (!context.mounted) return;
    final ok = await ensureDeepSeekPrivacyConsent(
      context,
      store: ref.read(privacyConsentStoreProvider),
    );
    if (!ok || !context.mounted) return;
  }

  final result = await ref.read(reviewServiceProvider).start(
        subjectId,
        mode: mode,
      );
  if (!context.mounted) return;
  result.when(
    success: (_) {},
    failure: (f) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.userMessage)),
      );
    },
  );
}
