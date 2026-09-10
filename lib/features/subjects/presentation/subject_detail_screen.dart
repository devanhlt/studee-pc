import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/widgets/app_shortcuts.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/history/presentation/history_list.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';
import 'package:studee_pc/features/subjects/presentation/study_notes_export_dialog.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsActionsProvider).open(widget.subjectId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openImport() {
    context.push('/subjects/${widget.subjectId}/import');
  }

  Future<void> _exportStudyNotes(Subject subject) async {
    final format = await showStudyNotesFormatDialog(context);
    if (format == null || !mounted) return;

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất tài liệu',
      fileName: '${subject.name}-ghi-chu.${format.fileExtension}',
      type: FileType.custom,
      allowedExtensions: [format.fileExtension],
    );
    if (path == null) return;

    if (mounted) {
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
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu: $out')),
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

  void _selectTab(int index) {
    if (_tabs.index == index) return;
    _tabs.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubject = ref.watch(subjectByIdProvider(widget.subjectId));

    return asyncSubject.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Môn học')),
        body: const Center(child: Text('Không tải được môn học.')),
      ),
      data: (subject) {
        if (subject == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Môn học')),
            body: const Center(child: Text('Không tìm thấy môn học.')),
          );
        }

        return CallbackShortcuts(
          bindings: {
            AppShortcuts.activator(LogicalKeyboardKey.digit1): () =>
                _selectTab(0),
            AppShortcuts.activator(LogicalKeyboardKey.digit2): () =>
                _selectTab(1),
            AppShortcuts.activator(LogicalKeyboardKey.digit3): () =>
                _selectTab(2),
          },
          child: Focus(
            // Don't steal focus from tab content (solve text field / shortcuts).
            canRequestFocus: false,
            child: Scaffold(
              appBar: AppBar(
                title: Text(subject.name),
                actions: [
                  IconButton(
                    tooltip: 'Làm mới',
                    onPressed: () {
                      switch (_tabs.index) {
                        case 0:
                          ref.invalidate(
                            subjectByIdProvider(widget.subjectId),
                          );
                        case 1:
                          ref.invalidate(
                            subjectKnowledgeProvider(widget.subjectId),
                          );
                        case 2:
                          ref.invalidate(
                            subjectHistoryProvider(widget.subjectId),
                          );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Xuất tài liệu',
                    onPressed: () => _exportStudyNotes(subject),
                    icon: const Icon(Icons.upload_outlined),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton.filled(
                      tooltip: 'Nhập kiến thức',
                      onPressed: _openImport,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: const Color(0xFF1A1208),
                      ),
                      icon: const Icon(Icons.library_add),
                    ),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabs,
                  tabAlignment: TabAlignment.fill,
                  tabs: [
                    Tab(text: AppShortcuts.label('Giải', '1')),
                    Tab(text: AppShortcuts.label('Kiến thức', '2')),
                    Tab(text: AppShortcuts.label('Lịch sử', '3')),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabs,
                children: [
                  SolveScreen(
                    subjectId: widget.subjectId,
                    embedded: true,
                    shortcutsActive: _tabs.index == 0,
                  ),
                  _KnowledgeTab(subjectId: widget.subjectId),
                  HistoryList(subjectId: widget.subjectId),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KnowledgeTab extends ConsumerWidget {
  const _KnowledgeTab({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectKnowledgeProvider(subjectId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Không tải được kiến thức.')),
      data: (items) {
        if (items.isEmpty) {
          return const _TabEmpty(
            message: 'Chưa có kiến thức. Hãy nhập tài liệu để bắt đầu.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = items[i];
            return ListTile(
              tileColor: AppColors.elevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              title: StudyMarkdown(
                u.content,
                compact: true,
                maxLines: 4,
              ),
              subtitle: Text(
                '${u.type.labelVi} · ${u.verificationStatus.labelVi}',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
