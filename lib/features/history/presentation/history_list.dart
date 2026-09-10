import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
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
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text('Không tải được lịch sử giải.'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Chưa có phiên giải câu hỏi.',
                style: TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final fmt = DateFormat('dd/MM/yyyy HH:mm');
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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

            return Container(
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudyMarkdown(
                    preview.isEmpty
                        ? '(Không có văn bản xem trước)'
                        : preview,
                    compact: true,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      fmt.format(item.createdAt.toLocal()),
                      inputVi,
                      if (statusVi.isNotEmpty) statusVi,
                      if (confidence != null) 'Tin cậy: $confidence',
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  if (answer.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    StudyMarkdown(
                      'Đáp án: $answer',
                      compact: true,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = subjectId;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giải')),
      body: id == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Chọn một môn học để xem lịch sử giải.',
                  style: TextStyle(color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : HistoryList(subjectId: id),
    );
  }
}
