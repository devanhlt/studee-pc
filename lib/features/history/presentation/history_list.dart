import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/utils/answer_display.dart';
import 'package:studee_pc/core/utils/user_facing_copy.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

/// Lists solve sessions for a subject (tab or `/history` route).
class HistoryList extends ConsumerWidget {
  const HistoryList({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectHistoryProvider(subjectId));
    final theme = Theme.of(context).textTheme;
    return async.when(
      loading: () => const StudeeSkeletonList(),
      error: (_, _) => const StudeeStatusState(
        icon: AppIcons.error,
        title: 'Không tải được lịch sử',
        message: 'Hãy thử làm mới.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const StudeeStatusState(
            icon: AppIcons.history,
            title: 'Chưa có lần giải nào',
            message: 'Hãy thử ở tab Giải hoặc Luyện tập.',
          );
        }
        final fmt = DateFormat('dd/MM/yyyy HH:mm');
        return ListView.separated(
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppLayout.gapSm),
          itemBuilder: (_, i) {
            final item = items[i];
            final preview = (item.preview ?? '').trim();
            final answer = AnswerDisplay.contentOnly(
              label: item.answerLabel,
              content: item.answerContent,
            );
            final confidence = item.confidence == null
                ? null
                : ConfidenceLevel.fromWire(item.confidence!).labelVi;
            final statusVi = UserFacingCopy.sessionStatusVi(item.status);
            final inputVi = UserFacingCopy.inputTypeVi(item.inputType);

            return StudeeCard(
              accentColor: AppColors.accent,
              onTap: () => context.push(
                '/subjects/$subjectId/history/${item.sessionId}',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StudyMarkdown(
                          preview.isEmpty
                              ? '(Không có nội dung xem trước)'
                              : preview,
                          compact: true,
                          maxLines: 3,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _confirmDelete(
                            context,
                            ref,
                            subjectId: subjectId,
                            sessionId: item.sessionId,
                          );
                        },
                        icon: const Icon(
                          AppIcons.delete,
                          size: AppIcons.sizeAction,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.gapSm),
                  Wrap(
                    spacing: AppLayout.gapXs,
                    runSpacing: AppLayout.gapXs,
                    children: [
                      StudeePill(
                        label: fmt.format(item.createdAt.toLocal()),
                      ),
                      if (inputVi.isNotEmpty) StudeePill(label: inputVi),
                      if (statusVi.isNotEmpty) StudeePill(label: statusVi),
                      if (confidence != null)
                        StudeePill(label: 'Tin cậy: $confidence'),
                    ],
                  ),
                  if (answer.isNotEmpty) ...[
                    const SizedBox(height: AppLayout.gapSm),
                    StudyMarkdown(
                      'Đáp án: $answer',
                      compact: true,
                      maxLines: 2,
                      style: theme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppLayout.gapXs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem chi tiết',
                          style: theme.labelMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          AppIcons.chevronRight,
                          size: AppIcons.sizeMicro,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref, {
  required String subjectId,
  required String sessionId,
  bool popOnSuccess = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Xóa lần giải này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(subjectsActionsProvider).deleteSolveSession(
        subjectId: subjectId,
        sessionId: sessionId,
      );
  if (!context.mounted) return;
  if (popOnSuccess) {
    Navigator.of(context).maybePop();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa lần giải.')),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = subjectId;
    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: const StudeeGlassAppBar(title: 'Lịch sử giải'),
      body: id == null
          ? const StudeeStatusState(
              icon: AppIcons.history,
              title: 'Chưa chọn môn học',
              message: 'Chọn một môn học để xem lịch sử giải.',
            )
          : HistoryList(subjectId: id),
    );
  }
}

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({
    super.key,
    required this.subjectId,
    required this.sessionId,
  });

  final String subjectId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      subjectHistoryDetailProvider(
        (subjectId: subjectId, sessionId: sessionId),
      ),
    );
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Chi tiết lần giải',
        actions: [
          IconButton(
            tooltip: 'Xóa',
            onPressed: () => _confirmDelete(
              context,
              ref,
              subjectId: subjectId,
              sessionId: sessionId,
              popOnSuccess: true,
            ),
            icon: const Icon(AppIcons.delete),
          ),
        ],
      ),
      body: async.when(
        loading: () => const StudeeSkeletonList(count: 2),
        error: (_, _) => const StudeeStatusState(
          icon: AppIcons.error,
          title: 'Không tải được chi tiết',
          message: 'Thử mở lại lần giải này.',
        ),
        data: (detail) {
          if (detail == null) {
            return const StudeeStatusState(
              icon: AppIcons.empty,
              title: 'Không tìm thấy phiên giải',
              message: 'Phiên này có thể đã bị xóa.',
            );
          }

          final answer = AnswerDisplay.contentOnly(
            label: detail.answerLabel,
            content: detail.answerContent,
            shortAnswer: detail.shortAnswer,
          );
          final questionText = _questionText(detail);
          final confidence = detail.confidence == null
              ? null
              : ConfidenceLevel.fromWire(detail.confidence!);
          final notes = UserFacingCopy.friendlyWarnings(detail.warnings);

          return ListView(
            padding: AppLayout.pageInsets(context),
            children: [
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        fmt.format(detail.createdAt.toLocal()),
                        UserFacingCopy.inputTypeVi(detail.inputType),
                        UserFacingCopy.sessionStatusVi(detail.status),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Câu hỏi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    StudyMarkdown(
                      questionText.isEmpty
                          ? '(Không có nội dung câu hỏi)'
                          : questionText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đáp án gợi ý',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (answer.isEmpty)
                      const Text(
                        '(Chưa có đáp án)',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          height: 1.35,
                        ),
                      )
                    else
                      StudyMarkdown(
                        answer,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                          height: 1.35,
                        ),
                      ),
                    if (confidence != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Tin cậy: ${confidence.labelVi} · '
                        '${detail.modelKnowledgeUsed ? 'Gợi ý từ AI' : 'Từ tài liệu đã nhập'}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...notes.map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Giải thích',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    StudyMarkdown(
                      (detail.explanationMarkdown ?? '').trim().isEmpty
                          ? '(Không có giải thích)'
                          : detail.explanationMarkdown!,
                    ),
                    if (detail.references.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Nguồn tham khảo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...detail.references.map((r) {
                        final title = (r.sourceTitle ?? '').trim().isEmpty
                            ? r.localId
                            : r.sourceTitle!;
                        final page =
                            r.page == null ? '' : ' · trang ${r.page}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $title$page',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              height: 1.35,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  static String _questionText(SolveHistoryDetail detail) {
    final parsed = detail.parsedQuestion;
    if (parsed != null) {
      final content = '${parsed['content'] ?? ''}'.trim();
      if (content.isNotEmpty) {
        final choices = parsed['choices'];
        if (choices is List && choices.isNotEmpty) {
          final buf = StringBuffer(content);
          for (final c in choices) {
            if (c is! Map) continue;
            final label = '${c['label'] ?? ''}'.trim();
            final body = '${c['content'] ?? ''}'.trim();
            if (label.isEmpty && body.isEmpty) continue;
            buf.writeln();
            buf.write(label.isEmpty ? body : '$label. $body');
          }
          return buf.toString().trim();
        }
        return content;
      }
    }
    return (detail.rawInputText ?? '').trim();
  }
}
