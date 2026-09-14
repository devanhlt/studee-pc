import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/features/practice/presentation/practice_chat_panel.dart';
import 'package:studee_pc/features/review/application/review_service.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

/// Ôn tập: Socratic chat over every saved question, with progress and cancel.
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
        ),
      ReviewStage.running => const _RunningReview(),
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
                    StudeeSectionLabel('Ôn $count câu đã lưu với Trợ lý Stud.'),
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppLayout.gapSm),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppLayout.gapMd),
                    FilledButton.icon(
                      onPressed: () => startReviewSession(
                        context,
                        ref,
                        subjectId,
                      ),
                      icon: const Icon(AppIcons.review),
                      label: const Text('Bắt đầu ôn tập'),
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
  });

  final String subjectId;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudeeStatusState(
      icon: AppIcons.checkCircle,
      title: 'Đã ôn xong $total câu',
      message: 'Bạn có thể ôn lại từ đầu, hoặc chuyển sang Luyện / Giải.',
      actionLabel: 'Ôn lại từ đầu',
      onAction: () => startReviewSession(context, ref, subjectId),
    );
  }
}

class _RunningReview extends ConsumerWidget {
  const _RunningReview();

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
        Padding(
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
                    TextButton(
                      onPressed: () =>
                          ref.read(reviewServiceProvider).cancel(),
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
        ),
        Expanded(
          child: PracticeChatPanel(
            showCancelAlways: false,
            completedMessage: lastDone
                ? 'Đã ôn xong tất cả câu hỏi.'
                : 'Đã xong câu này. Bấm “Câu tiếp” để ôn câu sau.',
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

Future<void> startReviewSession(
  BuildContext context,
  WidgetRef ref,
  String subjectId,
) async {
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

  final result = await ref.read(reviewServiceProvider).start(subjectId);
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
