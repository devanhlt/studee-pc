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
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/features/review/application/review_service.dart';
import 'package:studee_pc/features/review/presentation/review_panel.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

enum _WorkspaceMode { solve, practice, review }

bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

_WorkspaceMode _initialModeFromTab(String? tab) {
  switch (tab) {
    case 'review':
      return _WorkspaceMode.review;
    case 'practice':
      return _WorkspaceMode.practice;
    default:
      return _WorkspaceMode.solve;
  }
}

/// Subject workspace with Giải / Luyện / Ôn tập tabs; Báo cáo / Kiến thức / Lịch sử in menu.
class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    this.initialTab,
  });

  final String subjectId;

  /// Optional `solve` / `practice` / `review` from the route query.
  final String? initialTab;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  late _WorkspaceMode _mode;

  /// Set after discard confirm so [PopScope] can complete the pop.
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _mode = _initialModeFromTab(widget.initialTab);
    // Drop any prior Giải / Luyện / Ôn tập work before first paint so the
    // embedded SolveScreen does not hydrate the previous subject's session.
    ref.read(solveServiceProvider).reset();
    ref.read(practiceServiceProvider).reset();
    ref.read(reviewServiceProvider).finish();
    ref.read(solveTabDraftProvider.notifier).state = '';
    ref.read(practiceTabDraftProvider.notifier).state = '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Cancel any in-flight OCR / LLM work left from the previous subject.
      await _discardAllSessions();
      if (!mounted) return;
      await ref.read(subjectsActionsProvider).open(widget.subjectId);
    });
  }

  void _openImport() {
    if (_isMobile) return;
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
    }
  }

  Future<void> _discardAllSessions() async {
    await _discardIncomplete(_WorkspaceMode.solve);
    await _discardIncomplete(_WorkspaceMode.practice);
    await _discardIncomplete(_WorkspaceMode.review);
  }

  Future<bool> _showDiscardProgressDialog() async {
    final reviewRunning =
        ref.read(reviewServiceProvider).hasIncompleteSession;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: reviewRunning ? const Text('Hủy ôn tập?') : null,
        content: Text(
          reviewRunning
              ? 'Tiến trình ôn tập hiện tại sẽ bị hủy. Không thể hoàn tác.'
              : 'Bạn có muốn hủy bỏ tiến trình hiện tại?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            style: reviewRunning
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(reviewRunning ? 'Hủy ôn tập' : 'Hủy và chuyển'),
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
    setState(() => _mode = mode);
    await ref.read(subjectsActionsProvider).open(widget.subjectId);
  }

  Future<void> _exportStudyNotes(Subject subject) async {
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
      final fileName = '${subject.name}-ghi-chu.md';
      final tempPath = p.join(tempDir.path, fileName);
      final out = await ref.read(subjectsActionsProvider).exportStudyNotes(
            subjectId: subject.id,
            subjectName: subject.name,
            destinationPath: tempPath,
          );
      final bytes = await File(out).readAsBytes();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Xuất tài liệu',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['md'],
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
    ref.invalidate(subjectByIdProvider(widget.subjectId));
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
        final reviewRunning = (ref.watch(reviewStateProvider).asData?.value ??
                    ref.read(reviewServiceProvider).current)
                .stage ==
            ReviewStage.running;
        final focusReview = _mode == _WorkspaceMode.review && reviewRunning;

        final subtitle = switch (_mode) {
          _WorkspaceMode.solve =>
            solveBusy ? 'Đang giải…' : 'Giải câu hỏi',
          _WorkspaceMode.practice => 'Luyện từng bước',
          _WorkspaceMode.review => 'Ôn tập',
        };

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
            topBar: focusReview
                ? null
                : StudeeGlassAppBar(
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
                if (!_isMobile)
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
                      case _HeaderMenuAction.report:
                        context.push('/subjects/${widget.subjectId}/report');
                      case _HeaderMenuAction.knowledge:
                        context.push('/subjects/${widget.subjectId}/knowledge');
                      case _HeaderMenuAction.history:
                        context.push('/subjects/${widget.subjectId}/history');
                      case _HeaderMenuAction.export:
                        _exportStudyNotes(subject);
                      case _HeaderMenuAction.refresh:
                        _refresh();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _HeaderMenuAction.report,
                      child: Text('Báo cáo'),
                    ),
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
                if (!focusReview)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.pagePadding,
                      AppLayout.gapXs,
                      AppLayout.pagePadding,
                      AppLayout.gapSm,
                    ),
                    child: StudeeSegmentedControl<_WorkspaceMode>(
                      selected: _mode,
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
                        showModeToggle: false,
                        initialSurfaceMode: SolveSurfaceMode.solve,
                      ),
                    _WorkspaceMode.practice => SolveScreen(
                        key: const ValueKey('workspace-practice'),
                        subjectId: widget.subjectId,
                        embedded: true,
                        showModeToggle: false,
                        initialSurfaceMode: SolveSurfaceMode.practice,
                      ),
                    _WorkspaceMode.review => ReviewPanel(
                        subjectId: widget.subjectId,
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

enum _HeaderMenuAction { report, knowledge, history, export, refresh }
