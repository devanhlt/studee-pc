import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/history/presentation/history_list.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';
import 'package:studee_pc/features/subjects/presentation/study_notes_export_dialog.dart';

enum _WorkspaceMode { solve, knowledge, history }

/// Subject workspace — body is always **Giải**; Kiến thức / Lịch sử open
/// from the header overflow (⋯) menu.
class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  _WorkspaceMode _mode = _WorkspaceMode.solve;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsActionsProvider).open(widget.subjectId);
    });
  }

  void _openImport() {
    context.push('/subjects/${widget.subjectId}/import');
  }

  Future<void> _setMode(_WorkspaceMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    // Make sure the subject DB is open, then refresh list providers.
    await ref.read(subjectsActionsProvider).open(widget.subjectId);
    if (!mounted) return;
    switch (mode) {
      case _WorkspaceMode.knowledge:
        ref.invalidate(subjectKnowledgeProvider(widget.subjectId));
      case _WorkspaceMode.history:
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
      case _WorkspaceMode.solve:
        break;
    }
  }

  Future<void> _exportStudyNotes(Subject subject) async {
    final format = await showStudyNotesFormatDialog(context);
    if (format == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Đang tạo tài liệu bằng AI…\nCó thể mất một lúc.',
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${subject.name}-ghi-chu.${format.fileExtension}';
      final tempPath = p.join(tempDir.path, fileName);
      final out = await ref.read(subjectsActionsProvider).exportStudyNotes(
            subjectId: subject.id,
            subjectName: subject.name,
            destinationPath: tempPath,
            format: format,
          );
      final bytes = await File(out).readAsBytes();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Xuất tài liệu',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format.fileExtension],
        bytes: Uint8List.fromList(bytes),
      );
      if (saved == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu: $saved')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final message = e is AppFailure
          ? e.userMessage
          : 'Xuất tài liệu thất bại: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _refresh() {
    switch (_mode) {
      case _WorkspaceMode.solve:
        ref.invalidate(subjectByIdProvider(widget.subjectId));
      case _WorkspaceMode.knowledge:
        ref.invalidate(subjectKnowledgeProvider(widget.subjectId));
      case _WorkspaceMode.history:
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubject = ref.watch(subjectByIdProvider(widget.subjectId));

    return asyncSubject.when(
      loading: () => const StudeePageScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => StudeePageScaffold(
        topBar: const StudeeGlassAppBar(title: 'Môn học'),
        body: const Center(child: Text('Không tải được môn học.')),
      ),
      data: (subject) {
        if (subject == null) {
          return const StudeePageScaffold(
            topBar: StudeeGlassAppBar(title: 'Môn học'),
            body: Center(child: Text('Không tìm thấy môn học.')),
          );
        }

        final subtitle = switch (_mode) {
          _WorkspaceMode.solve => 'Giải câu hỏi',
          _WorkspaceMode.knowledge => 'Kiến thức hỗ trợ',
          _WorkspaceMode.history => 'Lịch sử giải',
        };

        return Focus(
          canRequestFocus: false,
          child: StudeePageScaffold(
            topBar: StudeeGlassAppBar(
              title: subject.name,
              subtitle: subtitle,
              leading: _mode == _WorkspaceMode.solve
                  ? IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    )
                  : IconButton(
                      tooltip: 'Về Giải',
                      onPressed: () => _setMode(_WorkspaceMode.solve),
                      icon: const Icon(Icons.arrow_back),
                    ),
              actions: [
                IconButton(
                  tooltip: 'Nhập kiến thức',
                  onPressed: _openImport,
                  icon: const Icon(Icons.library_add_outlined),
                ),
                PopupMenuButton<_HeaderMenuAction>(
                  tooltip: 'Thêm',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case _HeaderMenuAction.knowledge:
                        _setMode(_WorkspaceMode.knowledge);
                      case _HeaderMenuAction.history:
                        _setMode(_WorkspaceMode.history);
                      case _HeaderMenuAction.export:
                        _exportStudyNotes(subject);
                      case _HeaderMenuAction.refresh:
                        _refresh();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _HeaderMenuAction.knowledge,
                      child: Text('Kiến thức'),
                    ),
                    PopupMenuItem(
                      value: _HeaderMenuAction.history,
                      child: Text('Lịch sử'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: _HeaderMenuAction.export,
                      child: Text('Xuất tài liệu'),
                    ),
                    PopupMenuItem(
                      value: _HeaderMenuAction.refresh,
                      child: Text('Làm mới'),
                    ),
                  ],
                ),
              ],
            ),
            body: switch (_mode) {
              _WorkspaceMode.solve => SolveScreen(
                  subjectId: widget.subjectId,
                  embedded: true,
                  shortcutsActive: true,
                ),
              _WorkspaceMode.knowledge => _KnowledgePanel(
                  subjectId: widget.subjectId,
                  onImport: _openImport,
                  onBackToSolve: () => _setMode(_WorkspaceMode.solve),
                ),
              _WorkspaceMode.history => _HistoryPanel(
                  subjectId: widget.subjectId,
                  onBackToSolve: () => _setMode(_WorkspaceMode.solve),
                ),
            },
          ),
        );
      },
    );
  }
}

enum _HeaderMenuAction { knowledge, history, export, refresh }

class _KnowledgePanel extends ConsumerWidget {
  const _KnowledgePanel({
    required this.subjectId,
    required this.onImport,
    required this.onBackToSolve,
  });

  final String subjectId;
  final VoidCallback onImport;
  final VoidCallback onBackToSolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectKnowledgeProvider(subjectId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppLayout.pageInsets(context).copyWith(bottom: 0),
          child: StudeeGlass(
            borderRadius: 14,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StudeeSectionLabel('Kiến thức'),
                const SizedBox(height: 10),
                const Text(
                  'Dùng khi giải câu hỏi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kiến thức đã nhập giúp đáp án bám tài liệu của bạn.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onImport,
                        icon: const Icon(Icons.library_add, size: 18),
                        label: const Text('Nhập thêm'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onBackToSolve,
                      child: const Text('Giải ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được kiến thức.\n$e',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _SupportEmpty(
                  icon: Icons.menu_book_outlined,
                  title: 'Chưa có kiến thức',
                  message:
                      'Nhập tài liệu để Studee giải dựa trên nội dung bạn đã lưu.',
                  actionLabel: 'Nhập kiến thức',
                  onAction: onImport,
                );
              }
              return ListView.separated(
                padding: AppLayout.pageInsets(context),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = items[i];
                  return StudeeCard(
                    accentColor: AppColors.accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.type.labelVi,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StudyMarkdown(
                          u.content,
                          compact: true,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.subjectId,
    required this.onBackToSolve,
  });

  final String subjectId;
  final VoidCallback onBackToSolve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppLayout.pageInsets(context).copyWith(bottom: 8),
          child: StudeeGlass(
            borderRadius: 14,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StudeeSectionLabel('Lịch sử'),
                      SizedBox(height: 10),
                      Text(
                        'Các lần giải trước',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xem lại câu hỏi đã giải trong môn này.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onBackToSolve,
                  child: const Text('Giải tiếp'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: HistoryList(subjectId: subjectId)),
      ],
    );
  }
}

class _SupportEmpty extends StatelessWidget {
  const _SupportEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.accent.withValues(alpha: 0.85)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.secondaryText.withValues(alpha: 0.95),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
