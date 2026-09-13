import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/app_shortcuts.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/answer_display.dart';
import 'package:studee_pc/core/utils/user_facing_copy.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/entities/solve_result.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/features/practice/presentation/practice_chat_panel.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/mobile_image_crop.dart';
import 'package:studee_pc/features/solver/presentation/question_input_screen.dart';
import 'package:studee_pc/features/solver/presentation/scan_question_screen.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

final solveStateProvider = StreamProvider.autoDispose<SolveSessionState>((ref) {
  return ref.watch(solveServiceProvider).states;
});

/// Typed-but-not-submitted question draft on the Giải tab.
final solveTabDraftProvider = StateProvider<String>((ref) => '');

/// Typed-but-not-submitted question draft on the Luyện tab (idle only).
final practiceTabDraftProvider = StateProvider<String>((ref) => '');

enum SolveSurfaceMode { solve, practice }

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({
    super.key,
    required this.subjectId,
    this.embedded = false,
    this.shortcutsActive = true,
    this.showModeToggle = true,
    this.initialSurfaceMode = SolveSurfaceMode.solve,
  });

  final String subjectId;

  /// When true, render without its own [Scaffold]/AppBar] (for subject tabs).
  final bool embedded;

  /// When embedded, set true only while this tab is visible so ⌘/Ctrl+↵ works.
  final bool shortcutsActive;

  /// Standalone solve route keeps the Giải/Luyện toggle; workspace tabs hide it.
  final bool showModeToggle;

  final SolveSurfaceMode initialSurfaceMode;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  final _textController = TextEditingController();
  final _ocrController = TextEditingController();

  /// Region picker only — pipeline busy comes from [SolveSessionState.stage].
  bool _pickingRegion = false;

  late SolveSurfaceMode _surfaceMode = widget.initialSurfaceMode;

  SolveService get _service => ref.read(solveServiceProvider);
  PracticeService get _practice => ref.read(practiceServiceProvider);

  bool get _isProcessing => _service.current.stage.isInProgress;
  bool get _practiceBusy => _practice.current.stage.isBusy;

  @override
  void initState() {
    super.initState();
    final current = _service.current;
    final raw = current.rawText?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (current.needsOcrReview) {
        _ocrController.text = raw;
      } else if (current.needsQuestionConfirm || current.result == null) {
        _textController.text = raw;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _syncTabDraft();
      if (widget.showModeToggle) {
        final restored =
            await _practice.restoreIncompleteIfNeeded(widget.subjectId);
        if (!mounted) return;
        if (restored || _practice.hasIncompleteSession) {
          setState(() => _surfaceMode = SolveSurfaceMode.practice);
          return;
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant SolveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSurfaceMode != widget.initialSurfaceMode) {
      _surfaceMode = widget.initialSurfaceMode;
    }
  }

  @override
  void dispose() {
    // Do not cancel the solve pipeline — it keeps running in SolveService.
    _textController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  Future<bool> _ensureApiKey() async {
    // Warm Keychain once; later Mathpix/DeepSeek reads hit the in-memory cache.
    try {
      await _service.prepareCredentials();
    } on Object catch (_) {
      // Still try hasApiKey — it may surface a clearer failure.
    }
    if (await _service.hasApiKey()) {
      if (!mounted) return false;
      final store = ref.read(privacyConsentStoreProvider);
      return ensureDeepSeekPrivacyConsent(context, store: store);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.'),
        ),
      );
      context.push('/settings');
    }
    return false;
  }

  void _syncTabDraft() {
    final text = _textController.text;
    if (_surfaceMode == SolveSurfaceMode.practice) {
      ref.read(practiceTabDraftProvider.notifier).state = text;
    } else {
      ref.read(solveTabDraftProvider.notifier).state = text;
    }
  }

  void _clearTabDraft() {
    if (_surfaceMode == SolveSurfaceMode.practice) {
      ref.read(practiceTabDraftProvider.notifier).state = '';
    } else {
      ref.read(solveTabDraftProvider.notifier).state = '';
    }
  }

  Future<void> _solveText() async {
    if (_isProcessing || _pickingRegion || _practiceBusy) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast(_surfaceMode == SolveSurfaceMode.practice
          ? 'Hãy dán câu hỏi trước khi luyện.'
          : 'Hãy dán câu hỏi trước khi giải.');
      await _openQuestionEditor();
      return;
    }
    if (!await _ensureApiKey()) return;
    _clearTabDraft();
    if (_surfaceMode == SolveSurfaceMode.practice) {
      final result = await _practice.startFromText(
        subjectId: widget.subjectId,
        text: text,
      );
      _handlePractice(result);
      return;
    }
    if (_isProcessing) return;
    final result = await _service.solveFromText(
      subjectId: widget.subjectId,
      text: text,
    );
    _handle(result);
  }

  Future<bool> _ensurePrivacy() async {
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _solveFromImageBytes(
    Uint8List bytes, {
    required String emptyMessage,
    String inputType = 'image',
  }) async {
    if (_isProcessing || _practiceBusy) return;
    if (bytes.isEmpty) {
      _toast(emptyMessage);
      return;
    }
    if (!await _ensureApiKey()) return;
    _clearTabDraft();
    if (_surfaceMode == SolveSurfaceMode.practice) {
      final practiceType = switch (inputType) {
        'screenshot' => 'practice_screenshot',
        'camera' => 'practice_camera',
        _ => 'practice_image',
      };
      final result = await _practice.startFromImage(
        subjectId: widget.subjectId,
        bytes: bytes,
        inputType: practiceType,
      );
      _handlePractice(result);
      return;
    }
    if (_isProcessing) return;
    final result = await _service.solveFromImage(
      subjectId: widget.subjectId,
      bytes: bytes,
      inputType: inputType,
    );
    if (result is Failure &&
        result.failureOrNull?.code == 'ocr_review_required') {
      if (mounted) {
        _ocrController.text = _service.current.rawText ?? '';
        setState(() {});
      }
      return;
    }
    _handle(result);
  }

  Future<void> _solveImage() async {
    if (_isProcessing || _pickingRegion || _practiceBusy) return;
    if (!await _ensurePrivacy()) return;
    if (!mounted) return;
    try {
      final captured = await captureAndCropImage(
        context,
        capture: () => ref.read(platformIntegrationProvider).pickImage(),
        emptyMessage: 'Ảnh không có nội dung. Chọn file khác nhé.',
      );
      if (captured == null || !mounted) return;
      await _solveFromImageBytes(
        captured.bytes,
        emptyMessage: 'Ảnh không có nội dung. Chọn file khác nhé.',
      );
    } on AppFailure catch (f) {
      _toast(f.userMessage);
    }
  }

  Future<void> _capture() async {
    if (_isProcessing || _pickingRegion || _practiceBusy) return;
    if (!await _ensurePrivacy()) return;
    setState(() => _pickingRegion = true);
    try {
      final captured =
          await ref.read(platformIntegrationProvider).captureRegion();
      if (!mounted) return;
      setState(() => _pickingRegion = false);
      if (captured == null) {
        _toast('Đã hủy chọn vùng.');
        return;
      }
      await _solveFromImageBytes(
        captured.bytes,
        emptyMessage: 'Ảnh chụp không có nội dung. Thử lại nhé.',
        inputType: 'screenshot',
      );
    } on ScreenCaptureFailure catch (f) {
      if (mounted) {
        setState(() => _pickingRegion = false);
        _toast(f.userMessage);
      }
    } on AppFailure catch (f) {
      if (mounted) {
        setState(() => _pickingRegion = false);
        _toast(f.userMessage);
      }
    }
  }

  Future<void> _openCamera() async {
    if (_isProcessing || _pickingRegion || _practiceBusy) return;
    if (!await _ensurePrivacy()) return;
    if (!mounted) return;
    try {
      final captured = await ScanQuestionScreen.open(context);
      if (captured == null || !mounted) return;
      await _solveFromImageBytes(
        captured.bytes,
        emptyMessage: 'Ảnh từ camera không có nội dung. Thử lại nhé.',
        inputType: 'camera',
      );
    } on AppFailure catch (f) {
      _toast(f.userMessage);
    }
  }

  Widget _inputSourceMenu({required bool inputsLocked}) {
    final platform = ref.watch(platformIntegrationProvider);
    final tooltip = platform.supportsCamera
        ? 'Ảnh & camera'
        : 'Ảnh & chụp màn hình';
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          tooltip: tooltip,
          onPressed: inputsLocked
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          icon: const Icon(AppIcons.photo),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.image),
          onPressed: inputsLocked ? null : _solveImage,
          child: const Text('Chọn ảnh'),
        ),
        if (platform.supportsScreenCapture)
          MenuItemButton(
            leadingIcon: const Icon(AppIcons.capture),
            onPressed: inputsLocked ? null : _capture,
            child: const Text('Chụp màn hình'),
          ),
        if (platform.supportsCamera)
          MenuItemButton(
            leadingIcon: const Icon(AppIcons.camera),
            onPressed: inputsLocked ? null : _openCamera,
            child: const Text('Quét câu hỏi'),
          ),
      ],
    );
  }

  Future<void> _continueOcr() async {
    if (_isProcessing || _pickingRegion) return;
    final text = _ocrController.text.trim();
    if (text.isEmpty) {
      _toast('Nội dung câu hỏi đang trống. Hãy dán đề vào.');
      return;
    }
    if (!await _ensureApiKey()) return;
    if (_isProcessing) return;
    final result = await _service.continueWithReviewedText(
      subjectId: widget.subjectId,
      reviewedText: text,
    );
    _handle(result);
  }

  void _beginSolveAgain() {
    if (_isProcessing) return;
    final r = _service.beginResolveAgain();
    r.when(
      success: (_) {
        _textController.text = _service.current.rawText ?? '';
        _syncTabDraft();
        setState(() {});
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  Future<void> _confirmQuestionAndSolve() async {
    if (_isProcessing) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast('Câu hỏi đang trống. Hãy dán đề vào.');
      return;
    }
    if (!await _ensureApiKey()) return;
    if (_isProcessing) return;
    final result = await _service.solveFromText(
      subjectId: widget.subjectId,
      text: text,
    );
    _handle(result);
  }

  Future<void> _cancelSolve() async {
    await _service.cancel();
  }

  void _toast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handle(Result<SolveResult> result) {
    result.when(
      success: (_) {
        if (!mounted) return;
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
      },
      failure: (f) {
        if (!mounted) return;
        if (f is CancelledFailure || f.code == 'cancelled') return;
        if (f is MissingApiKeyFailure) context.push('/settings');
        if (f.code == 'ocr_review_required') {
          _ocrController.text = _service.current.rawText ?? '';
          setState(() {});
          return;
        }
        _toast(f.userMessage);
        setState(() {});
      },
    );
  }

  void _handlePractice(Result<void> result) {
    result.when(
      success: (_) {
        if (!mounted) return;
        setState(() {});
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
      },
      failure: (f) {
        if (!mounted) return;
        if (f is CancelledFailure || f.code == 'cancelled') return;
        if (f is MissingApiKeyFailure) context.push('/settings');
        _toast(f.userMessage);
        setState(() {});
      },
    );
  }

  void _newQuestion() {
    if (_isProcessing || _practiceBusy) return;
    _service.reset();
    _practice.reset();
    _textController.clear();
    _ocrController.clear();
    _clearTabDraft();
    setState(() {});
  }

  void _newPracticeQuestion() {
    _practice.reset();
    _textController.clear();
    _clearTabDraft();
    setState(() {});
  }

  Future<void> _openQuestionEditor() async {
    if (_isProcessing || _pickingRegion || _practiceBusy) return;
    final isPractice = _surfaceMode == SolveSurfaceMode.practice;
    final text = await QuestionInputScreen.open(
      context,
      initialText: _textController.text,
      hintText: isPractice
          ? 'Dán câu hỏi cần luyện…'
          : 'Dán nội dung câu hỏi…',
    );
    if (!mounted || text == null) return;
    setState(() => _textController.text = text);
    _syncTabDraft();
  }

  Future<void> _cancelPractice() async {
    await _practice.cancel();
    if (mounted) setState(() {});
  }

  Widget _modeToggle({required bool enabled}) {
    return StudeeSegmentedControl<SolveSurfaceMode>(
      enabled: enabled,
      selected: _surfaceMode,
      onChanged: (mode) {
        if (mode == _surfaceMode) return;
        setState(() => _surfaceMode = mode);
      },
      segments: const [
        StudeeSegment(
          value: SolveSurfaceMode.solve,
          label: 'Giải',
          icon: AppIcons.solve,
        ),
        StudeeSegment(
          value: SolveSurfaceMode.practice,
          label: 'Luyện tập',
          icon: AppIcons.practice,
        ),
      ],
    );
  }

  Widget _wrapWithModeToggle({
    required bool enabled,
    required Widget child,
  }) {
    if (!widget.showModeToggle) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppLayout.pageInsets(context).copyWith(bottom: 10, top: 8),
          child: _modeToggle(enabled: enabled),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _idleQuestionPreview({
    required bool inputsLocked,
    List<Widget> belowFooter = const [],
  }) {
    final isPractice = _surfaceMode == SolveSurfaceMode.practice;
    final question = _textController.text.trim();
    final hasQuestion = question.isNotEmpty;

    return Padding(
      padding: AppLayout.pageInsets(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppLayout.cardBorder,
                      onTap: inputsLocked ? null : _openQuestionEditor,
                      child: StudeeGlass(
                        padding: const EdgeInsets.all(AppLayout.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Câu hỏi',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Sửa',
                                  onPressed: inputsLocked
                                      ? null
                                      : _openQuestionEditor,
                                  icon: const Icon(AppIcons.edit),
                                ),
                                _inputSourceMenu(inputsLocked: inputsLocked),
                              ],
                            ),
                            if (!hasQuestion)
                              Text(
                                'Chạm để nhập hoặc dán đề bài…',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.secondaryText,
                                      height: 1.4,
                                    ),
                              )
                            else
                              StudyMarkdown(question),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_pickingRegion) ...[
                    const SizedBox(height: AppLayout.gapMd),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Đang chọn vùng chụp… kéo khung quanh câu hỏi',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasQuestion) ...[
            const SizedBox(height: AppLayout.gapMd),
            StudeeGlassFooter(
              padding: AppLayout.footerInsets,
              child: StudeeGradientButton(
                onPressed: inputsLocked ? null : _solveText,
                icon: isPractice ? AppIcons.practice : AppIcons.solve,
                label: isPractice
                    ? AppShortcuts.label('Bắt đầu luyện', '↵')
                    : AppShortcuts.label('Giải', '↵'),
              ),
            ),
          ],
          ...belowFooter,
        ],
      ),
    );
  }

  Widget _practiceIdleInput({required bool inputsLocked}) {
    return _idleQuestionPreview(
      inputsLocked: inputsLocked,
      belowFooter: [
        if (_practice.current.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _practice.current.errorMessage!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _processingPanel(SolveSessionState state) {
    return Padding(
      padding: AppLayout.pageInsets(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: StudeeGlass(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudeeGradientProgress(label: state.stage.labelVi),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn có thể làm việc khác, tiến trình vẫn chạy nền.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _cancelSolve,
                        child: const Text('Hủy'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(solveStateProvider);
    final state = async.asData?.value ?? _service.current;
    final practiceAsync = ref.watch(practiceStateProvider);
    final practice = practiceAsync.asData?.value ?? _practice.current;
    final isProcessing = state.stage.isInProgress;
    final inputsLocked = isProcessing || _pickingRegion || _practiceBusy;
    final practiceSessionOpen = practice.stage != PracticeStage.idle &&
        !(practice.stage == PracticeStage.failed && practice.messages.isEmpty);
    final modeSwitchEnabled =
        !isProcessing && !_practiceBusy && !practiceSessionOpen;

    if (_surfaceMode == SolveSurfaceMode.practice && practiceSessionOpen) {
      return _wrapWithModeToggle(
        enabled: modeSwitchEnabled,
        child: PracticeChatPanel(
          onNewQuestion: _newPracticeQuestion,
          onCancel: _cancelPractice,
        ),
      );
    }

    if (_surfaceMode == SolveSurfaceMode.practice) {
      return _wrapWithModeToggle(
        enabled: modeSwitchEnabled,
        child: _practiceIdleInput(inputsLocked: inputsLocked),
      );
    }

    final showInputForm = !isProcessing &&
        state.result == null &&
        !state.needsOcrReview &&
        !state.needsQuestionConfirm;

    final Widget body;
    if (isProcessing) {
      body = _processingPanel(state);
    } else if (state.result != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: AppLayout.pageInsets(context).copyWith(bottom: 8),
              children: [
                if (widget.embedded &&
                    (state.stage == SolvePipelineStage.offlineFailure ||
                        state.stage == SolvePipelineStage.partialFailure)) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _service.reset();
                        setState(() {});
                      },
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
                if (state.rawText != null &&
                    state.rawText!.trim().isNotEmpty) ...[
                  CollapsedQuestionTile(text: state.rawText!),
                  const SizedBox(height: 12),
                ],
                SolveResultView(
                  result: state.result!,
                  subjectId: widget.subjectId,
                  showActions: false,
                ),
              ],
            ),
          ),
          StudeeGlassFooter(
            child: SolveResultActions(
              result: state.result!,
              subjectId: widget.subjectId,
              onSolveAgain: _beginSolveAgain,
              onReset: _newQuestion,
            ),
          ),
        ],
      );
    } else if (showInputForm) {
      body = _idleQuestionPreview(
        inputsLocked: inputsLocked,
        belowFooter: [
          if (widget.embedded &&
              (state.stage == SolvePipelineStage.offlineFailure ||
                  state.stage == SolvePipelineStage.partialFailure)) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _service.reset();
                  setState(() {});
                },
                child: const Text('Đóng'),
              ),
            ),
          ],
          if (state.errorMessage != null && state.result == null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _service.reset();
                setState(() {});
              },
              child: const Text('Thử lại'),
            ),
          ],
        ],
      );
    } else {
      body = ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          if (widget.embedded &&
              (state.stage == SolvePipelineStage.offlineFailure ||
                  state.stage == SolvePipelineStage.partialFailure)) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _service.reset();
                  setState(() {});
                },
                child: const Text('Đóng'),
              ),
            ),
          ],
          if (state.needsOcrReview) ...[
            const Text(
              'Chữ nhận dạng chưa rõ, hãy chỉnh lại trước khi giải:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ocrController,
              enabled: !inputsLocked,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: inputsLocked ? null : _continueOcr,
              child: Text(AppShortcuts.label('Tiếp tục giải', '↵')),
            ),
            const SizedBox(height: 24),
          ],
          if (state.needsQuestionConfirm) ...[
            const Text(
              'Chỉnh lại câu hỏi rồi xác nhận để giải lại',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              enabled: !inputsLocked,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: inputsLocked ? null : _confirmQuestionAndSolve,
                  child: Text(AppShortcuts.label('Xác nhận và giải', '↵')),
                ),
                TextButton(
                  onPressed: inputsLocked ? null : _newQuestion,
                  child: const Text('Câu hỏi mới'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (state.errorMessage != null && state.result == null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _service.reset();
                setState(() {});
              },
              child: const Text('Thử lại'),
            ),
          ],
        ],
      );
    }

    final wrapped = CallbackShortcuts(
      bindings: widget.shortcutsActive
          ? <ShortcutActivator, VoidCallback>{
              AppShortcuts.activator(LogicalKeyboardKey.enter): () {
                if (inputsLocked) return;
                if (state.needsOcrReview) {
                  _continueOcr();
                } else if (state.needsQuestionConfirm) {
                  _confirmQuestionAndSolve();
                } else if (showInputForm) {
                  _solveText();
                }
              },
            }
          : const <ShortcutActivator, VoidCallback>{},
      child: Focus(
        child: _wrapWithModeToggle(
          enabled: modeSwitchEnabled,
          child: body,
        ),
      ),
    );

    if (widget.embedded) return wrapped;

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Giải câu hỏi',
        actions: [
          if (isProcessing)
            TextButton(
              onPressed: _cancelSolve,
              child: const Text('Hủy'),
            ),
          if (state.stage == SolvePipelineStage.offlineFailure ||
              state.stage == SolvePipelineStage.partialFailure)
            TextButton(
              onPressed: () {
                _service.reset();
                setState(() {});
              },
              child: const Text('Đóng'),
            ),
        ],
      ),
      body: wrapped,
    );
  }
}

/// Collapsed question preview — tap to expand full text / markdown.
class CollapsedQuestionTile extends StatelessWidget {
  const CollapsedQuestionTile({super.key, required this.text});

  final String text;

  /// Plain preview without raw LaTeX delimiters for the collapsed subtitle.
  static String plainPreview(String input) {
    var t = input.replaceAll('\r\n', '\n');
    t = t.replaceAllMapped(
      RegExp(r'\$\$[\s\S]*?\$\$'),
      (_) => ' [công thức] ',
    );
    t = t.replaceAllMapped(
      RegExp(r'\\\[([\s\S]*?)\\\]'),
      (_) => ' [công thức] ',
    );
    t = t.replaceAllMapped(
      RegExp(r'\$[^$\n]+\$'),
      (_) => ' [công thức] ',
    );
    t = t.replaceAllMapped(
      RegExp(r'\\\(([\s\S]*?)\\\)'),
      (_) => ' [công thức] ',
    );
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: StudeeGlass(
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            'Câu hỏi',
            style: theme.titleSmall,
          ),
          subtitle: Text(
            plainPreview(text),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StudyMarkdown(text),
            ),
          ],
        ),
      ),
    );
  }
}

class SolveResultView extends ConsumerWidget {
  const SolveResultView({
    super.key,
    required this.result,
    required this.subjectId,
    this.onSolveAgain,
    this.onReset,
    this.compact = false,
    this.showActions = true,
  });

  final SolveResult result;
  final String subjectId;
  final VoidCallback? onSolveAgain;
  final VoidCallback? onReset;
  final bool compact;

  /// When false, omit the bottom action row (parent can pin it separately).
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answer = AnswerDisplay.contentOnly(
      label: result.finalAnswerLabel,
      content: result.finalAnswerContent,
      shortAnswer: result.shortAnswer,
    );

    final knowledgeLabel = result.fromImportedKnowledge
        ? 'Từ tài liệu bạn đã nhập'
        : 'Gợi ý từ AI';
    final notes = UserFacingCopy.friendlyWarnings(result.warnings);

    final confidenceLevel = switch (result.confidence) {
      ConfidenceLevel.high => 2,
      ConfidenceLevel.medium => 1,
      ConfidenceLevel.low || ConfidenceLevel.conflict => 0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudeeGlass(
          gradientBorder: true,
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đáp án gợi ý',
                style: TextStyle(
                  fontSize: compact ? 13.5 : 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              if (answer.isEmpty)
                Text(
                  '(Chưa có đáp án ngắn, xem phần giải thích bên dưới)',
                  style: TextStyle(
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    height: 1.35,
                  ),
                )
              else
                StudyMarkdown(
                  answer,
                  compact: compact,
                  style: TextStyle(
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StudeeConfidenceMeter(
                    level: confidenceLevel,
                    label: 'Tin cậy: ${result.confidence.labelVi}',
                  ),
                  StudeePill(
                    label: knowledgeLabel,
                    color: result.fromImportedKnowledge
                        ? AppColors.success
                        : AppColors.violet,
                    icon: result.fromImportedKnowledge
                        ? AppIcons.book
                        : AppIcons.sparkle,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...notes.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                w,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const StudeeSectionLabel('Giải thích'),
        const SizedBox(height: 10),
        StudyMarkdown(
          result.explanationMarkdown,
          compact: compact,
        ),
        if (result.references.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showReferencesPopup(
                context,
                result.references,
              ),
              icon: const Icon(AppIcons.book, size: AppIcons.sizeInline),
              label: Text('Nguồn tham khảo (${result.references.length})'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        if (showActions) ...[
          const SizedBox(height: 16),
          SolveResultActions(
            result: result,
            subjectId: subjectId,
            onSolveAgain: onSolveAgain,
            onReset: onReset,
          ),
        ],
      ],
    );
  }
}

/// Primary result actions — used inline or as a sticky footer.
class SolveResultActions extends ConsumerWidget {
  const SolveResultActions({
    super.key,
    required this.result,
    required this.subjectId,
    this.onSolveAgain,
    this.onReset,
  });

  final SolveResult result;
  final String subjectId;
  final VoidCallback? onSolveAgain;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answer = AnswerDisplay.contentOnly(
      label: result.finalAnswerLabel,
      content: result.finalAnswerContent,
      shortAnswer: result.shortAnswer,
    );

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: StudeeGradientButton(
            onPressed: () async {
              final r = await ref
                  .read(solveServiceProvider)
                  .saveResultToSubject(subjectId: subjectId);
              if (!context.mounted) return;
              r.when(
                success: (_) {
                  ref.invalidate(subjectKnowledgeProvider(subjectId));
                  ref.invalidate(subjectQuestionsProvider(subjectId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu vào môn học.'),
                    ),
                  );
                },
                failure: (f) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(f.userMessage)),
                  );
                },
              );
            },
            label: 'Lưu vào môn học',
            icon: AppIcons.bookmarkAdd,
          ),
        ),
        if (onReset != null) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onReset,
              child: const Text(
                'Câu hỏi mới',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
        ],
        PopupMenuButton<_ResultMoreAction>(
          tooltip: 'Thêm',
          padding: EdgeInsets.zero,
          onSelected: (action) async {
            switch (action) {
              case _ResultMoreAction.copy:
                final text = [
                  if (answer.isNotEmpty) answer,
                  '',
                  result.explanationMarkdown,
                ].join('\n');
                await FlutterClipboard.copy(text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép.')),
                  );
                }
              case _ResultMoreAction.solveAgain:
                onSolveAgain?.call();
              case _ResultMoreAction.markWrong:
                final r = await ref.read(solveServiceProvider).markIncorrect(
                      note: '',
                      subjectId: subjectId,
                    );
                if (!context.mounted) return;
                r.when(
                  success: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã ghi nhận phản hồi của bạn.'),
                      ),
                    );
                  },
                  failure: (f) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(f.userMessage)),
                    );
                  },
                );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ResultMoreAction.copy,
              child: Text('Sao chép'),
            ),
            if (onSolveAgain != null)
              const PopupMenuItem(
                value: _ResultMoreAction.solveAgain,
                child: Text('Giải lại'),
              ),
            const PopupMenuItem(
              value: _ResultMoreAction.markWrong,
              child: Text('Báo kết quả sai'),
            ),
          ],
          icon: const Icon(AppIcons.more),
        ),
      ],
    );
  }
}

enum _ResultMoreAction { copy, solveAgain, markWrong }
void _showReferencesPopup(
  BuildContext context,
  List<ResultReference> references,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Tham chiếu (${references.length})'),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: references.length,
              separatorBuilder: (_, _) => const Divider(height: 20),
              itemBuilder: (_, index) {
                final r = references[index];
                final meta = [
                  if (r.sourceTitle != null) r.sourceTitle!,
                  if (r.page != null) 'trang ${r.page}',
                  r.type.labelVi,
                ].join(' · ');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (r.snippet != null && r.snippet!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      StudyMarkdown(
                        r.snippet!,
                        compact: true,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      );
    },
  );
}
