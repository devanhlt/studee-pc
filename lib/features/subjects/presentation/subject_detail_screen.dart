import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/history/presentation/history_list.dart';
import 'package:studee_pc/features/review/application/review_service.dart';
import 'package:studee_pc/features/review/presentation/review_panel.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';
import 'package:studee_pc/features/subjects/presentation/study_notes_export_dialog.dart';

enum _WorkspaceMode { solve, practice, review, knowledge, history }

bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Subject workspace with Giải / Luyện / Ôn tập tabs; Kiến thức & Lịch sử in menu.
class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  _WorkspaceMode _mode = _WorkspaceMode.solve;

  /// Last Giải / Luyện / Ôn tập tab — kept while viewing Kiến thức or Lịch sử.
  _WorkspaceMode _primaryTab = _WorkspaceMode.solve;

  /// Set after discard confirm so [PopScope] can complete the pop.
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(subjectsActionsProvider).open(widget.subjectId);
      if (!mounted) return;
      final practice = ref.read(practiceServiceProvider);
      final restored =
          await practice.restoreIncompleteIfNeeded(widget.subjectId);
      if (!mounted) return;
      if (restored || practice.hasIncompleteSession) {
        setState(() {
          _mode = _WorkspaceMode.practice;
          _primaryTab = _WorkspaceMode.practice;
        });
      }
    });
  }

  void _openImport() {
    context.push('/subjects/${widget.subjectId}/import');
  }

  /// Active / unfinished work on [mode] that should confirm before leaving.
  bool _hasIncompleteWork(_WorkspaceMode mode) {
    switch (mode) {
      case _WorkspaceMode.solve:
        final solve = ref.read(solveServiceProvider).current;
        final draft = ref.read(solveTabDraftProvider).trim();
        return solve.stage.isInProgress ||
            solve.needsOcrReview ||
            solve.needsQuestionConfirm ||
            (solve.result == null &&
                (solve.rawText?.trim().isNotEmpty ?? false)) ||
            draft.isNotEmpty;
      case _WorkspaceMode.practice:
        final draft = ref.read(practiceTabDraftProvider).trim();
        return ref.read(practiceServiceProvider).hasIncompleteSession ||
            draft.isNotEmpty;
      case _WorkspaceMode.review:
        return ref.read(reviewServiceProvider).hasIncompleteSession;
      case _WorkspaceMode.knowledge:
      case _WorkspaceMode.history:
        return false;
    }
  }

  Future<void> _discardIncomplete(_WorkspaceMode mode) async {
    switch (mode) {
      case _WorkspaceMode.solve:
        final solve = ref.read(solveServiceProvider);
        if (solve.current.stage.isInProgress) {
          await solve.cancel();
        }
        solve.reset();
        ref.read(solveTabDraftProvider.notifier).state = '';
      case _WorkspaceMode.practice:
        await ref.read(practiceServiceProvider).cancel();
        ref.read(practiceTabDraftProvider.notifier).state = '';
      case _WorkspaceMode.review:
        await ref.read(reviewServiceProvider).cancel();
      case _WorkspaceMode.knowledge:
      case _WorkspaceMode.history:
        break;
    }
  }

  Future<void> _discardAllSessions() async {
    await _discardIncomplete(_WorkspaceMode.solve);
    await _discardIncomplete(_WorkspaceMode.practice);
    await _discardIncomplete(_WorkspaceMode.review);
  }

  Future<bool> _showDiscardProgressDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Bạn có muốn hủy bỏ tiến trình hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy và chuyển'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmLeaveCurrentTab() async {
    if (!_hasIncompleteWork(_mode)) return true;
    if (!await _showDiscardProgressDialog()) return false;
    await _discardIncomplete(_mode);
    return true;
  }

  /// Back from subject detail: same dialog as tab change; clears every session.
  Future<bool> _confirmLeaveSubject() async {
    final hasWork = _hasIncompleteWork(_WorkspaceMode.solve) ||
        _hasIncompleteWork(_WorkspaceMode.practice) ||
        _hasIncompleteWork(_mode);
    if (!hasWork) return true;
    if (!await _showDiscardProgressDialog()) return false;
    await _discardAllSessions();
    return true;
  }

  Future<void> _handleBack() async {
    if (!await _confirmLeaveSubject()) return;
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _setMode(_WorkspaceMode mode) async {
    if (_mode == mode) return;
    if (!await _confirmLeaveCurrentTab()) return;
    if (!mounted) return;
    setState(() {
      _mode = mode;
      if (mode == _WorkspaceMode.solve ||
          mode == _WorkspaceMode.practice ||
          mode == _WorkspaceMode.review) {
        _primaryTab = mode;
      }
    });
    await ref.read(subjectsActionsProvider).open(widget.subjectId);
    if (!mounted) return;
    switch (mode) {
      case _WorkspaceMode.knowledge:
        ref.invalidate(subjectKnowledgeProvider(widget.subjectId));
      case _WorkspaceMode.history:
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
      case _WorkspaceMode.solve:
      case _WorkspaceMode.practice:
      case _WorkspaceMode.review:
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
                'Đang tạo tài liệu bằng Trợ lý Stud…\nCó thể mất một lúc.',
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
      case _WorkspaceMode.practice:
      case _WorkspaceMode.review:
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
        atmosphereIntensity: AppLayout.atmospherePage,
        body: StudeeSkeletonList(),
      ),
      error: (_, _) => const StudeePageScaffold(
        atmosphereIntensity: AppLayout.atmospherePage,
        topBar: StudeeGlassAppBar(title: 'Môn học'),
        body: StudeeStatusState(
          icon: AppIcons.error,
          title: 'Không tải được môn học',
          message: 'Thử mở lại hoặc làm mới danh sách môn.',
        ),
      ),
      data: (subject) {
        if (subject == null) {
          return const StudeePageScaffold(
            atmosphereIntensity: AppLayout.atmospherePage,
            topBar: StudeeGlassAppBar(title: 'Môn học'),
            body: StudeeStatusState(
              icon: AppIcons.empty,
              title: 'Không tìm thấy môn học',
              message: 'Môn này có thể đã bị xóa.',
            ),
          );
        }

        final solveAsync = ref.watch(solveStateProvider);
        final solveBusy = (solveAsync.asData?.value ??
                ref.read(solveServiceProvider).current)
            .stage
            .isInProgress;

        final subtitle = switch (_mode) {
          _WorkspaceMode.solve =>
            solveBusy ? 'Đang giải…' : 'Giải câu hỏi',
          _WorkspaceMode.practice => 'Luyện từng bước',
          _WorkspaceMode.review => 'Ôn tập',
          _WorkspaceMode.knowledge =>
            solveBusy ? 'Kiến thức · đang giải…' : 'Kiến thức hỗ trợ',
          _WorkspaceMode.history =>
            solveBusy ? 'Lịch sử · đang giải…' : 'Lịch sử giải',
        };

        final segmentSelected =
            (_mode == _WorkspaceMode.knowledge ||
                    _mode == _WorkspaceMode.history)
                ? _primaryTab
                : _mode;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleBack();
          },
          child: Focus(
          canRequestFocus: false,
          child: StudeePageScaffold(
            atmosphereIntensity: AppLayout.atmospherePage,
            topBar: StudeeGlassAppBar(
              title: subject.name,
              subtitle: subtitle,
              leading: IconButton(
                tooltip: 'Quay lại',
                onPressed: _handleBack,
                icon: const Icon(AppIcons.back),
              ),
              actions: [
                if (solveBusy && _mode != _WorkspaceMode.solve)
                  IconButton(
                    tooltip: 'Đang giải, mở tab Giải',
                    onPressed: () => _setMode(_WorkspaceMode.solve),
                    icon: const SizedBox(
                      width: AppIcons.sizeInline,
                      height: AppIcons.sizeInline,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Nhập kiến thức',
                  onPressed: _openImport,
                  icon: const Icon(AppIcons.libraryAdd),
                ),
                PopupMenuButton<_HeaderMenuAction>(
                  tooltip: 'Thêm',
                  icon: const Icon(AppIcons.moreVert),
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
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _HeaderMenuAction.knowledge,
                      child: Text('Kiến thức'),
                    ),
                    const PopupMenuItem(
                      value: _HeaderMenuAction.history,
                      child: Text('Lịch sử'),
                    ),
                    const PopupMenuItem(
                      value: _HeaderMenuAction.export,
                      child: Text('Xuất tài liệu'),
                    ),
                    if (!_isMobile)
                      const PopupMenuItem(
                        value: _HeaderMenuAction.refresh,
                        child: Text('Làm mới'),
                      ),
                  ],
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.pagePadding,
                    AppLayout.gapXs,
                    AppLayout.pagePadding,
                    AppLayout.gapSm,
                  ),
                  child: StudeeSegmentedControl<_WorkspaceMode>(
                    selected: segmentSelected,
                    onChanged: _setMode,
                    segments: const [
                      StudeeSegment(
                        value: _WorkspaceMode.solve,
                        label: 'Giải',
                        icon: AppIcons.solve,
                      ),
                      StudeeSegment(
                        value: _WorkspaceMode.practice,
                        label: 'Luyện',
                        icon: AppIcons.practice,
                      ),
                      StudeeSegment(
                        value: _WorkspaceMode.review,
                        label: 'Ôn tập',
                        icon: AppIcons.review,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (_mode) {
                    _WorkspaceMode.solve => SolveScreen(
                        key: const ValueKey('workspace-solve'),
                        subjectId: widget.subjectId,
                        embedded: true,
                        shortcutsActive: true,
                        showModeToggle: false,
                        initialSurfaceMode: SolveSurfaceMode.solve,
                      ),
                    _WorkspaceMode.practice => SolveScreen(
                        key: const ValueKey('workspace-practice'),
                        subjectId: widget.subjectId,
                        embedded: true,
                        shortcutsActive: true,
                        showModeToggle: false,
                        initialSurfaceMode: SolveSurfaceMode.practice,
                      ),
                    _WorkspaceMode.review => ReviewPanel(
                        subjectId: widget.subjectId,
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
              ],
            ),
          ),
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
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StudeeSectionLabel('Kiến thức'),
                const SizedBox(height: AppLayout.gapSm),
                Text(
                  'Dùng khi Trợ lý Stud giải bài',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppLayout.gapXs),
                Text(
                  'Càng nhiều tài liệu, đáp án càng sát với giáo trình bạn đang học.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppLayout.gapMd),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onImport,
                        icon: const Icon(
                          AppIcons.libraryAdd,
                          size: AppIcons.sizeInline,
                        ),
                        label: const Text('Nhập thêm'),
                      ),
                    ),
                    const SizedBox(width: AppLayout.gapSm),
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
        const SizedBox(height: AppLayout.gapSm),
        Expanded(
          child: async.when(
            loading: () => const StudeeSkeletonList(),
            error: (e, _) => StudeeStatusState(
              icon: AppIcons.error,
              title: 'Không tải được kiến thức',
              message: '$e',
            ),
            data: (items) {
              if (items.isEmpty) {
                return StudeeStatusState(
                  icon: AppIcons.book,
                  title: 'Chưa có kiến thức nào',
                  message:
                      'Thêm tài liệu vào đây để Trợ lý Stud giải bài dựa trên những gì bạn đã lưu.',
                  actionLabel: 'Nhập kiến thức',
                  onAction: onImport,
                );
              }
              return ListView.separated(
                padding: AppLayout.pageInsets(context),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppLayout.gapSm),
                itemBuilder: (_, i) {
                  final u = items[i];
                  return StudeeCard(
                    accentColor: AppColors.accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.type.labelVi,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppLayout.gapXs),
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
          padding:
              AppLayout.pageInsets(context).copyWith(bottom: AppLayout.gapSm),
          child: StudeeGlass(
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StudeeSectionLabel('Lịch sử'),
                      const SizedBox(height: AppLayout.gapSm),
                      Text(
                        'Các lần giải trước',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppLayout.gapXs),
                      Text(
                        'Xem lại những câu bạn đã giải trong môn này.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppLayout.gapSm),
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
