import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';
import 'package:studee_pc/features/subjects/presentation/study_notes_export_dialog.dart';

class SubjectsListScreen extends ConsumerWidget {
  const SubjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Môn học'),
        actions: [
          IconButton(
            tooltip: 'Nhập từ ZIP',
            onPressed: () => _importSubjectZip(context, ref),
            icon: const Icon(Icons.unarchive_outlined),
          ),
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: asyncSubjects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Không tải được danh sách môn học.',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const _EmptySubjectsState();
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref.invalidate(subjectsListProvider);
              await ref.read(subjectsListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _SubjectCard(subject: subjects[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: asyncSubjects.maybeWhen(
        data: (subjects) => subjects.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => _showCreateDialog(context, ref),
                tooltip: 'Thêm môn học',
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF1A1208),
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _EmptySubjectsState extends ConsumerWidget {
  const _EmptySubjectsState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: AppColors.secondaryText.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có môn học',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tạo môn học đầu tiên để nhập tài liệu và giải câu hỏi '
                'với kiến thức đã lưu.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Thêm môn học'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _importSubjectZip(context, ref),
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('Nhập từ ZIP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = subject.color != null
        ? Color(subject.color!)
        : AppColors.accent;
    final updated = DateFormat('dd/MM/yyyy HH:mm')
        .format(subject.updatedAt.toLocal());

    return Material(
      color: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/subjects/${subject.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  _iconFor(subject.icon),
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.sourceCount} nguồn · '
                      '${subject.knowledgeCount} mục kiến thức · '
                      '${subject.questionCount} câu',
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cập nhật: $updated',
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Thao tác',
                onSelected: (value) async {
                  switch (value) {
                    case 'rename':
                      await _showRenameDialog(context, ref, subject);
                    case 'export':
                      await _exportSubject(context, ref, subject);
                    case 'export_notes':
                      await _exportStudyNotes(context, ref, subject);
                    case 'delete':
                      await _showDeleteDialog(context, ref, subject);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                  PopupMenuItem(value: 'export', child: Text('Xuất ZIP')),
                  PopupMenuItem(
                    value: 'export_notes',
                    child: Text('Xuất tài liệu'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String? name) {
    return switch (name) {
      'science' => Icons.science_outlined,
      'calculate' => Icons.calculate_outlined,
      'history_edu' => Icons.history_edu_outlined,
      'language' => Icons.translate_outlined,
      _ => Icons.menu_book_outlined,
    };
  }
}

Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Thêm môn học'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Tên môn học',
              hintText: 'Ví dụ: Đại số tuyến tính',
              errorText: error,
            ),
            onSubmitted: (v) {
              final trimmed = v.trim();
              if (trimmed.isEmpty) {
                setLocal(() => error = 'Tên không được trống.');
                return;
              }
              Navigator.of(ctx).pop(trimmed);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setLocal(() => error = 'Tên không được trống.');
                  return;
                }
                Navigator.of(ctx).pop(trimmed);
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      );
    },
  );
  if (name == null || name.isEmpty) return;
  try {
    await ref.read(subjectsActionsProvider).create(name);
    ref.read(subjectsActionsProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo môn học "$name".')),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString() : 'Không tạo được môn học.',
          ),
        ),
      );
    }
  }
}

Future<void> _showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  Subject subject,
) async {
  final controller = TextEditingController(text: subject.name);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Đổi tên môn học'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Tên mới',
              errorText: error,
            ),
            onSubmitted: (v) {
              final trimmed = v.trim();
              if (trimmed.isEmpty) {
                setLocal(() => error = 'Tên không được trống.');
                return;
              }
              Navigator.of(ctx).pop(trimmed);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setLocal(() => error = 'Tên không được trống.');
                  return;
                }
                Navigator.of(ctx).pop(trimmed);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
    },
  );
  if (name == null || name.isEmpty || name == subject.name) return;
  await ref.read(subjectsActionsProvider).rename(subject.id, name);
  ref.read(subjectsActionsProvider).refresh();
}

Future<void> _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  Subject subject,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final maxPathHeight = MediaQuery.sizeOf(ctx).height * 0.4;
      return AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn sắp xóa "${subject.name}". Thao tác này không hoàn tác.'),
            const SizedBox(height: 12),
            const Text(
              'Thư mục sẽ bị xóa:',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPathHeight),
              child: SingleChildScrollView(
                child: SelectableText(
                  subject.folderPath,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ),
          ],
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
      );
    },
  );
  if (confirmed != true) return;
  await ref.read(subjectsActionsProvider).delete(subject.id);
  ref.read(subjectsActionsProvider).refresh();
}

Future<void> _exportSubject(
  BuildContext context,
  WidgetRef ref,
  Subject subject,
) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Xuất môn học',
    fileName: '${subject.name}.zip',
    type: FileType.custom,
    allowedExtensions: const ['zip'],
  );
  if (path == null) return;
  try {
    final out = await ref.read(subjectsActionsProvider).export(subject.id, path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất: $out')),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất thất bại: $e')),
      );
    }
  }
}

Future<void> _exportStudyNotes(
  BuildContext context,
  WidgetRef ref,
  Subject subject,
) async {
  final format = await showStudyNotesFormatDialog(context);
  if (format == null || !context.mounted) return;

  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Xuất tài liệu',
    fileName: '${subject.name}-ghi-chu.${format.fileExtension}',
    type: FileType.custom,
    allowedExtensions: [format.fileExtension],
  );
  if (path == null) return;

  if (context.mounted) {
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
  }

  try {
    final out = await ref.read(subjectsActionsProvider).exportStudyNotes(
          subjectId: subject.id,
          subjectName: subject.name,
          destinationPath: path,
          format: format,
        );
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu: $out')),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      final message = e is AppFailure
          ? e.userMessage
          : 'Xuất tài liệu thất bại: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

Future<void> _importSubjectZip(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.platform.pickFiles(
    dialogTitle: 'Nhập môn học từ ZIP',
    type: FileType.custom,
    allowedExtensions: const ['zip'],
    allowMultiple: false,
  );
  final path = picked?.files.single.path;
  if (path == null) return;
  try {
    final subject = await ref.read(subjectsActionsProvider).importZip(path);
    ref.read(subjectsActionsProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã nhập môn học "${subject.name}".')),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      final message = e is AppFailure
          ? e.userMessage
          : 'Nhập ZIP thất bại: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
