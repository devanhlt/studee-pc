import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

enum OverlayDisplayMode { compact, expanded }

final overlayModeProvider =
    StateProvider<OverlayDisplayMode>((ref) => OverlayDisplayMode.compact);

final overlaySubjectIdProvider = StateProvider<String?>((ref) => null);

enum OverlayShortcutAction { capture, paste }

/// Pending global-hotkey action for [OverlayPanel] to consume.
final overlayShortcutActionProvider =
    StateProvider<OverlayShortcutAction?>((ref) => null);

/// Compact / expanded always-on-top study overlay.
class OverlayPanel extends ConsumerStatefulWidget {
  const OverlayPanel({super.key});

  @override
  ConsumerState<OverlayPanel> createState() => _OverlayPanelState();
}

class _OverlayPanelState extends ConsumerState<OverlayPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final desktop = ref.read(desktopIntegrationProvider);
      await desktop.setAlwaysOnTop(true);
      final subjects = await ref.read(subjectsListProvider.future);
      if (subjects.isNotEmpty && ref.read(overlaySubjectIdProvider) == null) {
        ref.read(overlaySubjectIdProvider.notifier).state = subjects.first.id;
      }
    });
  }

  SolveService get _solve => ref.read(solveServiceProvider);

  Future<bool> _ensureReady() async {
    if (!await _solve.hasApiKey()) {
      _toast('Nhập khóa API DeepSeek');
      if (mounted) context.push('/settings');
      return false;
    }
    if (!mounted) return false;
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _capture() async {
    final subjectId = ref.read(overlaySubjectIdProvider);
    if (subjectId == null) {
      _toast('Chọn môn học trong cửa sổ chính trước.');
      return;
    }
    if (!await _ensureReady()) return;

    ref.read(overlayModeProvider.notifier).state = OverlayDisplayMode.expanded;
    final desktop = ref.read(desktopIntegrationProvider);
    try {
      final captured = await desktop.captureRegion();
      if (captured == null) {
        _toast('Đã hủy chọn vùng.');
        return;
      }
      if (captured.bytes.isEmpty) {
        _toast('Ảnh chụp trống — thử lại.');
        return;
      }
      final result = await _solve.solveFromImage(
        subjectId: subjectId,
        bytes: captured.bytes,
        inputType: 'screenshot',
      );
      result.when(
        success: (_) {},
        failure: (f) {
          if (f is MissingApiKeyFailure && mounted) context.push('/settings');
          if (f.code != 'ocr_review_required') _toast(f.userMessage);
        },
      );
    } on ScreenCaptureFailure catch (f) {
      _toast(f.userMessage);
    }
  }

  Future<void> _paste() async {
    final subjectId = ref.read(overlaySubjectIdProvider);
    if (subjectId == null) {
      _toast('Chọn môn học trong cửa sổ chính trước.');
      return;
    }
    if (!await _ensureReady()) return;

    final text = await FlutterClipboard.paste();
    if (text.trim().isEmpty) {
      _toast('Clipboard trống.');
      return;
    }
    ref.read(overlayModeProvider.notifier).state = OverlayDisplayMode.expanded;
    final result = await _solve.solveFromText(
      subjectId: subjectId,
      text: text,
    );
    result.when(
      success: (_) {},
      failure: (f) {
        if (f is MissingApiKeyFailure && mounted) context.push('/settings');
        _toast(f.userMessage);
      },
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OverlayShortcutAction?>(overlayShortcutActionProvider, (
      _,
      next,
    ) {
      if (next == null) return;
      ref.read(overlayShortcutActionProvider.notifier).state = null;
      switch (next) {
        case OverlayShortcutAction.capture:
          _capture();
        case OverlayShortcutAction.paste:
          _paste();
      }
    });

    final mode = ref.watch(overlayModeProvider);
    final solveAsync = ref.watch(solveStateProvider);
    final state = solveAsync.asData?.value ?? _solve.current;
    final media = MediaQuery.sizeOf(context);
    final maxHeight = media.height * 0.7;
    final isCompact = mode == OverlayDisplayMode.compact;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isCompact ? 220 : 420,
            minWidth: isCompact ? 160 : 280,
            maxHeight: maxHeight,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.elevated.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isCompact
                ? _CompactBar(
                    stage: state.stage,
                    onCapture: _capture,
                    onPaste: _paste,
                    onExpand: () {
                      ref.read(overlayModeProvider.notifier).state =
                          OverlayDisplayMode.expanded;
                    },
                  )
                : _ExpandedBody(
                    state: state,
                    subjectId: ref.watch(overlaySubjectIdProvider),
                    onCapture: _capture,
                    onPaste: _paste,
                    onCollapse: () {
                      ref.read(overlayModeProvider.notifier).state =
                          OverlayDisplayMode.compact;
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.stage,
    required this.onCapture,
    required this.onPaste,
    required this.onExpand,
  });

  final SolvePipelineStage stage;
  final VoidCallback onCapture;
  final VoidCallback onPaste;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final busy = stage != SolvePipelineStage.idle &&
        stage != SolvePipelineStage.completed &&
        stage != SolvePipelineStage.partialFailure &&
        stage != SolvePipelineStage.offlineFailure;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Chụp vùng',
            visualDensity: VisualDensity.compact,
            onPressed: busy ? null : onCapture,
            icon: const Icon(Icons.crop_free, color: AppColors.accent),
          ),
          IconButton(
            tooltip: 'Dán',
            visualDensity: VisualDensity.compact,
            onPressed: busy ? null : onPaste,
            icon: const Icon(Icons.content_paste),
          ),
          IconButton(
            tooltip: 'Mở rộng',
            visualDensity: VisualDensity.compact,
            onPressed: onExpand,
            icon: const Icon(Icons.open_in_full),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.state,
    required this.subjectId,
    required this.onCapture,
    required this.onPaste,
    required this.onCollapse,
  });

  final SolveSessionState state;
  final String? subjectId;
  final VoidCallback onCapture;
  final VoidCallback onPaste;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
            child: Row(
              children: [
                const Text(
                  'Studee',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Chụp',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCapture,
                  icon: const Icon(Icons.crop_free),
                ),
                IconButton(
                  tooltip: 'Dán',
                  visualDensity: VisualDensity.compact,
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste),
                ),
                IconButton(
                  tooltip: 'Thu gọn',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCollapse,
                  icon: const Icon(Icons.close_fullscreen),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (state.stage) {
      case SolvePipelineStage.idle:
        return const Text(
          'Chụp hoặc dán câu hỏi để bắt đầu.',
          style: TextStyle(color: AppColors.secondaryText),
        );
      case SolvePipelineStage.capturing:
      case SolvePipelineStage.recognizing:
      case SolvePipelineStage.parsing:
      case SolvePipelineStage.retrieving:
      case SolvePipelineStage.generating:
        return _StatusLine(state.stage.labelVi);
      case SolvePipelineStage.offlineFailure:
        return Text(
          state.errorMessage ?? 'Không kết nối được',
          style: const TextStyle(color: AppColors.error),
        );
      case SolvePipelineStage.partialFailure:
        if (state.result != null && subjectId != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.rawText != null &&
                  state.rawText!.trim().isNotEmpty) ...[
                CollapsedQuestionTile(text: state.rawText!),
                const SizedBox(height: 12),
              ],
              SolveResultView(
                result: state.result!,
                subjectId: subjectId!,
                compact: true,
              ),
            ],
          );
        }
        return Text(
          state.errorMessage ?? 'Hoàn tất một phần',
          style: const TextStyle(color: AppColors.secondaryText),
        );
      case SolvePipelineStage.completed:
        if (state.result != null && subjectId != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.rawText != null &&
                  state.rawText!.trim().isNotEmpty) ...[
                CollapsedQuestionTile(text: state.rawText!),
                const SizedBox(height: 12),
              ],
              SolveResultView(
                result: state.result!,
                subjectId: subjectId!,
                compact: true,
              ),
            ],
          );
        }
        return const Text('Hoàn tất');
    }
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// Standalone overlay route host (same window for this release).
class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: OverlayPanel(),
    );
  }
}
