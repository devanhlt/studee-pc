import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/theme/app_window_size.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/features/settings/presentation/ensure_activation_code.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

enum OverlayDisplayMode { compact, expanded }

final overlayModeProvider =
    StateProvider<OverlayDisplayMode>((ref) => OverlayDisplayMode.compact);

final overlaySubjectIdProvider = StateProvider<String?>((ref) => null);

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
      final desktop = ref.read(platformIntegrationProvider);
      await desktop.setAlwaysOnTop(true);
      final subjects = await ref.read(subjectsListProvider.future);
      if (subjects.isNotEmpty && ref.read(overlaySubjectIdProvider) == null) {
        ref.read(overlaySubjectIdProvider.notifier).state = subjects.first.id;
      }
    });
  }

  SolveService get _solve => ref.read(solveServiceProvider);

  Future<bool> _ensureReady() async {
    try {
      await _solve.prepareCredentials();
    } on Object catch (_) {}
    if (!mounted) return false;
    if (!await ensureActivationCode(
      context,
      hasCode: _solve.hasApiKey,
    )) {
      return false;
    }
    if (!mounted) return false;
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _capture() async {
    if (_solve.current.stage.isInProgress) return;
    final subjectId = ref.read(overlaySubjectIdProvider);
    if (subjectId == null) {
      _toast('Hãy chọn môn học ở cửa sổ chính trước.');
      return;
    }
    if (!await _ensureReady()) return;
    if (_solve.current.stage.isInProgress) return;

    ref.read(overlayModeProvider.notifier).state = OverlayDisplayMode.expanded;
    final desktop = ref.read(platformIntegrationProvider);
    try {
      final captured = await desktop.captureRegion();
      if (captured == null) {
        _toast('Đã hủy chọn vùng.');
        return;
      }
      if (captured.bytes.isEmpty) {
        _toast('Ảnh chụp không có nội dung. Thử lại nhé.');
        return;
      }
      if (_solve.current.stage.isInProgress) return;
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
    if (_solve.current.stage.isInProgress) return;
    final subjectId = ref.read(overlaySubjectIdProvider);
    if (subjectId == null) {
      _toast('Hãy chọn môn học ở cửa sổ chính trước.');
      return;
    }
    if (!await _ensureReady()) return;
    if (_solve.current.stage.isInProgress) return;

    final text = await FlutterClipboard.paste();
    if (text.trim().isEmpty) {
      _toast('Bộ nhớ tạm đang trống.');
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

  Future<void> _cancel() => _solve.cancel();

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            maxWidth: isCompact ? 220 : AppWindowSize.phoneWidth,
            minWidth: isCompact ? 160 : 280,
            maxHeight: maxHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.pagePadding),
            child: StudeeGlass(
              borderRadius: AppLayout.radiusPanel,
              gradientBorder: true,
              opacity: 0.92,
              child: isCompact
                  ? _CompactBar(
                      stage: state.stage,
                      onCapture: _capture,
                      onPaste: _paste,
                      onCancel: _cancel,
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
                      onCancel: _cancel,
                      onCollapse: () {
                        // Collapsing must not cancel the in-flight solve.
                        ref.read(overlayModeProvider.notifier).state =
                            OverlayDisplayMode.compact;
                      },
                    ),
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
    required this.onCancel,
    required this.onExpand,
  });

  final SolvePipelineStage stage;
  final VoidCallback onCapture;
  final VoidCallback onPaste;
  final VoidCallback onCancel;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final busy = stage.isInProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Chụp vùng',
            visualDensity: VisualDensity.compact,
            onPressed: busy ? null : onCapture,
            icon: const Icon(AppIcons.capture, color: AppColors.accent),
          ),
          IconButton(
            tooltip: 'Dán',
            visualDensity: VisualDensity.compact,
            onPressed: busy ? null : onPaste,
            icon: const Icon(AppIcons.paste),
          ),
          IconButton(
            tooltip: 'Mở rộng',
            visualDensity: VisualDensity.compact,
            onPressed: onExpand,
            icon: const Icon(AppIcons.expand),
          ),
          if (busy) ...[
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            IconButton(
              tooltip: 'Hủy',
              visualDensity: VisualDensity.compact,
              onPressed: onCancel,
              icon: const Icon(AppIcons.close, color: AppColors.error),
            ),
          ],
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
    required this.onCancel,
    required this.onCollapse,
  });

  final SolveSessionState state;
  final String? subjectId;
  final VoidCallback onCapture;
  final VoidCallback onPaste;
  final VoidCallback onCancel;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final busy = state.stage.isInProgress;

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
                if (busy)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Hủy'),
                  ),
                IconButton(
                  tooltip: 'Chụp',
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : onCapture,
                  icon: const Icon(AppIcons.capture),
                ),
                IconButton(
                  tooltip: 'Dán',
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : onPaste,
                  icon: const Icon(AppIcons.paste),
                ),
                IconButton(
                  tooltip: 'Thu gọn',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCollapse,
                  icon: const Icon(AppIcons.collapse),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusLine(state.stage.labelVi),
            const SizedBox(height: 12),
            const Text(
              'Bạn có thể thu gọn, tiến trình vẫn chạy nền.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        );
      case SolvePipelineStage.offlineFailure:
        return Text(
          state.errorMessage ?? 'Không có kết nối mạng',
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Standalone overlay route host (same window for this release).
class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: const [
          StudeeAtmosphere(intensity: AppLayout.atmospherePage),
          OverlayPanel(),
        ],
      ),
    );
  }
}
