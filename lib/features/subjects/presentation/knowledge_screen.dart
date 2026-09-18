import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/features/subjects/application/question_with_related_knowledge.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Standalone question-centric knowledge browser for a subject.
class SubjectKnowledgeScreen extends ConsumerStatefulWidget {
  const SubjectKnowledgeScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectKnowledgeScreen> createState() =>
      _SubjectKnowledgeScreenState();
}

class _SubjectKnowledgeScreenState
    extends ConsumerState<SubjectKnowledgeScreen> {
  QuestionWithRelatedKnowledge? _selected;

  void _openImport() {
    if (_isMobile) return;
    context.push('/subjects/${widget.subjectId}/import');
  }

  Future<void> _confirmDelete(QuestionWithRelatedKnowledge item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: const Text(
          'Câu hỏi và kiến thức liên quan (không dùng chung với câu khác) '
          'sẽ bị xóa. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(subjectsActionsProvider).deleteQuestionCascade(
          subjectId: widget.subjectId,
          questionId: item.question.id,
        );
    if (!mounted) return;
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final async =
        ref.watch(subjectKnowledgeQuestionsProvider(widget.subjectId));
    final subject =
        ref.watch(subjectByIdProvider(widget.subjectId)).asData?.value;
    final canImport = !_isMobile;
    final formatKind = formatKindForSubject(subject);
    final selected = _selected;

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Kiến thức',
        subtitle: subject?.name,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () {
            if (selected != null) {
              setState(() => _selected = null);
              return;
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/subjects/${widget.subjectId}');
            }
          },
          icon: const Icon(AppIcons.back),
        ),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'Xóa câu hỏi',
              onPressed: () => _confirmDelete(selected),
              icon: const Icon(AppIcons.delete),
            )
          else if (canImport)
            IconButton(
              tooltip: 'Nhập kiến thức',
              onPressed: _openImport,
              icon: const Icon(AppIcons.libraryAdd),
            ),
        ],
      ),
      body: async.when(
              loading: () => const StudeeSkeletonList(),
              error: (e, _) => StudeeStatusState(
                icon: AppIcons.error,
                title: 'Không tải được kiến thức',
                message: '$e',
              ),
              data: (items) {
                if (selected != null) {
                  final current = items
                      .where((i) => i.question.id == selected.question.id)
                      .firstOrNull;
                  if (current == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selected = null);
                    });
                    return const StudeeSkeletonList();
                  }
                  return _KnowledgeQuestionDetail(
                    item: current,
                    formatKind: formatKind,
                  );
                }
                if (items.isEmpty) {
                  return StudeeStatusState(
                    icon: AppIcons.book,
                    title: 'Chưa có câu hỏi nào',
                    message: canImport
                        ? 'Thêm tài liệu vào đây để Trợ lý Stud giải bài dựa trên những gì bạn đã lưu.'
                        : 'Trên điện thoại hãy dùng Nhập từ .stud để mang môn học (kèm kiến thức) từ máy tính.',
                    actionLabel: canImport ? 'Nhập kiến thức' : null,
                    onAction: canImport ? _openImport : null,
                  );
                }
                return ListView.separated(
                  padding: AppLayout.pageInsets(context),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppLayout.gapSm),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final q = item.question;
                    return StudeeCard(
                      accentColor: AppColors.accent,
                      onTap: () => setState(() => _selected = item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StudeePill(
                                label: q.questionType.labelVi,
                                color: AppColors.accent,
                              ),
                              if (item.relatedCount > 0)
                                StudeePill(
                                  label: '${item.relatedCount} kiến thức',
                                  color: AppColors.cyan,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.gapSm),
                          StudyMarkdown(
                            q.content,
                            compact: true,
                            maxLines: 4,
                            formatKind: formatKind,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _KnowledgeQuestionDetail extends StatelessWidget {
  const _KnowledgeQuestionDetail({
    required this.item,
    required this.formatKind,
  });

  final QuestionWithRelatedKnowledge item;
  final SubjectFormatKind formatKind;

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final theme = Theme.of(context).textTheme;
    final knowledge = item.allKnowledge;

    return ListView(
      padding: AppLayout.pageInsets(context).copyWith(bottom: 28),
      children: [
        StudeeGlass(
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Câu hỏi', style: theme.titleSmall),
              const SizedBox(height: AppLayout.gapSm),
              StudyMarkdown(q.content, formatKind: formatKind),
              if (q.choices.isNotEmpty) ...[
                const SizedBox(height: AppLayout.gapMd),
                for (final c in q.choices) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.label}. ',
                          style: theme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: StudyMarkdown(
                            c.content,
                            compact: true,
                            formatKind: formatKind,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if ((q.answerContent ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppLayout.gapMd),
                Text('Đáp án', style: theme.labelLarge),
                const SizedBox(height: AppLayout.gapXs),
                StudyMarkdown(
                  q.answerLabel != null && q.answerLabel!.isNotEmpty
                      ? '${q.answerLabel}. ${q.answerContent}'
                      : q.answerContent!,
                  formatKind: formatKind,
                ),
              ],
              if ((q.explanation ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppLayout.gapMd),
                Text('Giải thích', style: theme.labelLarge),
                const SizedBox(height: AppLayout.gapXs),
                StudyMarkdown(q.explanation!, formatKind: formatKind),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppLayout.gapSm),
        StudeeGlass(
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kiến thức liên quan', style: theme.titleSmall),
              const SizedBox(height: AppLayout.gapSm),
              if (knowledge.isEmpty)
                Text(
                  'Không có đơn vị kiến thức liên quan.',
                  style: theme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                )
              else
                for (var i = 0; i < knowledge.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppLayout.gapSm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: AppLayout.controlBorder,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.85),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          knowledge[i].type.labelVi,
                          style: theme.labelMedium,
                        ),
                        const SizedBox(height: AppLayout.gapXs),
                        StudyMarkdown(
                          knowledge[i].content,
                          formatKind: formatKind,
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
