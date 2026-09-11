import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';
import 'package:studee_pc/features/subjects/presentation/study_notes_export_dialog.dart';

class SubjectsListScreen extends ConsumerWidget {
  const SubjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsListProvider);

    return StudeePageScaffold(
      atmosphereIntensity: 1,
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
      topBar: _HomeHeader(
        onImport: () => _importSubjectZip(context, ref),
        onSettings: () => context.push('/settings'),
      ),
      body: asyncSubjects.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Không tải được danh sách môn học.',
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
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
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 88),
              itemCount: subjects.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 14 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const StudeeSectionLabel('Môn học của bạn');
                }
                return _SubjectCard(subject: subjects[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onImport,
    required this.onSettings,
  });

  final VoidCallback onImport;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDEE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Học sâu.\nNhớ chắc.',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mỗi môn một không gian — nhập kiến thức, giải đề, ôn có định hướng.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.secondaryText.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Nhập từ ZIP',
                onPressed: onImport,
                icon: const Icon(Icons.unarchive_outlined),
              ),
              IconButton(
                tooltip: 'Cài đặt',
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _HeroArtCard(),
              const SizedBox(height: 22),
              StudeeGlass(
                borderRadius: 16,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    const Text(
                      'Bắt đầu hành trình ôn tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo môn học đầu tiên — nhập tài liệu, giải câu hỏi, '
                      'và xây bộ nhớ kiến thức riêng của bạn.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.secondaryText.withValues(alpha: 0.95),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm môn học'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _importSubjectZip(context, ref),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Nhập từ ZIP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroArtCard extends StatelessWidget {
  const _HeroArtCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/studee-home-hero.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.elevated,
                  child: Center(
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 48,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Text(
                  'Ánh sáng cho từng trang ghi chú',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: AppColors.primaryText.withValues(alpha: 0.92),
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

    return StudeeCard(
      accentColor: color,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: () => context.push('/subjects/${subject.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
              ),
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
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${subject.sourceCount} nguồn · '
                  '${subject.knowledgeCount} mục · '
                  '${subject.questionCount} câu',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cập nhật $updated',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText.withValues(alpha: 0.75),
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
              PopupMenuItem(
                value: 'rename',
                child: Text('Đổi tên'),
              ),
              PopupMenuItem(
                value: 'export',
                child: Text('Xuất ZIP'),
              ),
              PopupMenuItem(
                value: 'export_notes',
                child: Text('Xuất tài liệu'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xóa'),
              ),
            ],
          ),
        ],
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
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      String? error;
      void submit(void Function(void Function()) setLocal) {
        final trimmed = controller.text.trim();
        if (trimmed.isEmpty) {
          setLocal(() => error = 'Nhập tên môn học.');
          return;
        }
        Navigator.of(ctx).pop(trimmed);
      }

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Dialog(
            backgroundColor: AppColors.elevated,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppColors.border.withValues(alpha: 0.85),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Thêm môn học',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tên môn, ví dụ Đại số…',
                          errorText: error,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.9),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (error != null) setLocal(() => error = null);
                        },
                        onSubmitted: (_) => submit(setLocal),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton(
                        onPressed: () => submit(setLocal),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tạo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      String? error;
      void submit(void Function(void Function()) setLocal) {
        final trimmed = controller.text.trim();
        if (trimmed.isEmpty) {
          setLocal(() => error = 'Nhập tên môn học.');
          return;
        }
        Navigator.of(ctx).pop(trimmed);
      }

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Dialog(
            backgroundColor: AppColors.elevated,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppColors.border.withValues(alpha: 0.85),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Đổi tên',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tên môn học…',
                          errorText: error,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.9),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (error != null) setLocal(() => error = null);
                        },
                        onSubmitted: (_) => submit(setLocal),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton(
                        onPressed: () => submit(setLocal),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
  try {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, '${subject.name}.zip');
    final out = await ref.read(subjectsActionsProvider).export(
          subject.id,
          tempPath,
        );
    final bytes = await File(out).readAsBytes();
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Xuất môn học',
      fileName: '${subject.name}.zip',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: Uint8List.fromList(bytes),
    );
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xuất: $saved')),
    );
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
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Xuất tài liệu',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [format.fileExtension],
      bytes: Uint8List.fromList(bytes),
    );
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xuất tài liệu: $saved')),
    );
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
  final picked = await FilePicker.pickFiles(
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
