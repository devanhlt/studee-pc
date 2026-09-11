import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/app_shortcuts.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/answer_display.dart';
import 'package:studee_pc/core/utils/user_facing_copy.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/entities/solve_result.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/features/solver/presentation/camera_capture_dialog.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

final solveStateProvider = StreamProvider.autoDispose<SolveSessionState>((ref) {
  return ref.watch(solveServiceProvider).states;
});

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({
    super.key,
    required this.subjectId,
    this.embedded = false,
    this.shortcutsActive = true,
  });

  final String subjectId;

  /// When true, render without its own [Scaffold]/AppBar] (for subject tabs).
  final bool embedded;

  /// When embedded in subject tabs, set true only for the active Giải tab so
  /// When embedded, set true only while Giải is visible so ⌘/Ctrl+↵ works.
  final bool shortcutsActive;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  final _textController = TextEditingController();
  final _ocrController = TextEditingController();
  final _textFocusNode = FocusNode();

  /// Region picker only — pipeline busy comes from [SolveSessionState.stage].
  bool _pickingRegion = false;

  SolveService get _service => ref.read(solveServiceProvider);

  bool get _isProcessing => _service.current.stage.isInProgress;

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
    if (widget.shortcutsActive &&
        !current.stage.isInProgress &&
        current.result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    // Do not cancel the solve pipeline — it keeps running in SolveService.
    _textFocusNode.dispose();
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
          content: Text('Nhập mã kích hoạt trong Cài đặt'),
        ),
      );
      context.push('/settings');
    }
    return false;
  }

  /// Privacy notice only — does not touch Keychain.
  Future<bool> _ensurePrivacy() async {
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _solveText() async {
    if (_isProcessing || _pickingRegion) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast('Nhập câu hỏi trước khi giải.');
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

  Future<void> _solveFromImageBytes(
    Uint8List bytes, {
    required String emptyMessage,
    String inputType = 'image',
  }) async {
    if (_isProcessing) return;
    if (bytes.isEmpty) {
      _toast(emptyMessage);
      return;
    }
    // Load DeepSeek + Mathpix in one Keychain unlock before OCR starts.
    try {
      await _service.prepareCredentials();
    } on Object catch (_) {}
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
    if (_isProcessing || _pickingRegion) return;
    if (!await _ensurePrivacy()) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    await _solveFromImageBytes(
      Uint8List.fromList(bytes),
      emptyMessage: 'Ảnh trống — hãy chọn file khác.',
    );
  }

  Future<void> _capture() async {
    if (_isProcessing || _pickingRegion) return;
    if (!await _ensurePrivacy()) return;
    setState(() => _pickingRegion = true);
    try {
      final captured =
          await ref.read(desktopIntegrationProvider).captureRegion();
      if (!mounted) return;
      setState(() => _pickingRegion = false);
      if (captured == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy chọn vùng.')),
        );
        return;
      }
      await _solveFromImageBytes(
        captured.bytes,
        emptyMessage: 'Ảnh chụp trống — thử lại.',
        inputType: 'screenshot',
      );
    } on ScreenCaptureFailure catch (f) {
      if (mounted) {
        setState(() => _pickingRegion = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      }
    }
  }

  Future<void> _openCamera() async {
    if (_isProcessing || _pickingRegion) return;
    if (!await _ensurePrivacy()) return;
    if (!mounted) return;
    final bytes = await showCameraCaptureDialog(context);
    if (bytes == null || !mounted) return;
    await _solveFromImageBytes(
      bytes,
      emptyMessage: 'Ảnh camera trống — thử lại.',
      inputType: 'camera',
    );
  }

  Future<void> _continueOcr() async {
    if (_isProcessing || _pickingRegion) return;
    final text = _ocrController.text.trim();
    if (text.isEmpty) {
      _toast('Nội dung câu hỏi không được trống.');
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
    if (_isProcessing || _pickingRegion) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast('Câu hỏi không được trống.');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  void _newQuestion() {
    if (_isProcessing) return;
    _service.reset();
    _textController.clear();
    _ocrController.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocusNode.requestFocus();
    });
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
                  borderRadius: 16,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        state.stage.labelVi,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn có thể quay lại — tiến trình vẫn chạy nền.',
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
    final isProcessing = state.stage.isInProgress;
    final inputsLocked = isProcessing || _pickingRegion;

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
      body = Padding(
        padding: AppLayout.pageInsets(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedded &&
                (state.stage == SolvePipelineStage.offlineFailure ||
                    state.stage == SolvePipelineStage.partialFailure))
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
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (!widget.shortcutsActive) return KeyEventResult.ignored;
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (inputsLocked || !showInputForm) {
                    return KeyEventResult.ignored;
                  }
                  final mod = HardwareKeyboard.instance.isMetaPressed ||
                      HardwareKeyboard.instance.isControlPressed;
                  if (!mod) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _solveText();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: StudeeGlass(
                  borderRadius: 16,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    enabled: !inputsLocked,
                    autofocus: widget.shortcutsActive,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText:
                          'Dán nội dung câu hỏi… (${AppShortcuts.chord('↵')} để giải)',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: false,
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            StudeeGlassFooter(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: inputsLocked ? null : _solveText,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(AppShortcuts.label('Giải', '↵')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton.outlined(
                        tooltip: 'Ảnh & camera',
                        onPressed: inputsLocked
                            ? null
                            : () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                        icon: const Icon(Icons.photo_outlined),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.image_outlined),
                        onPressed: inputsLocked ? null : _solveImage,
                        child: const Text('Chọn ảnh'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.crop_free),
                        onPressed: inputsLocked ? null : _capture,
                        child: const Text('Chụp màn hình'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.photo_camera_outlined),
                        onPressed: inputsLocked ? null : _openCamera,
                        child: const Text('Camera'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_pickingRegion) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Đang chọn vùng chụp…',
                style: TextStyle(color: AppColors.secondaryText),
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
        ),
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
              'Chữ nhận dạng chưa rõ — hãy chỉnh lại trước khi giải:',
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
              'Chỉnh câu hỏi rồi xác nhận để giải lại',
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
        child: body,
      ),
    );

    if (widget.embedded) return wrapped;

    return StudeePageScaffold(
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: StudeeGlass(
        borderRadius: 14,
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: const Text(
            'Câu hỏi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            text.replaceAll(RegExp(r'\s+'), ' ').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
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
        ? 'Từ tài liệu đã nhập'
        : 'Gợi ý từ AI';
    final notes = UserFacingCopy.friendlyWarnings(result.warnings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đáp án gợi ý',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        if (answer.isEmpty)
          Text(
            '(Chưa có đáp án ngắn — xem phần giải thích bên dưới)',
            style: TextStyle(
              fontSize: compact ? 16 : 18,
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
              fontSize: compact ? 17 : 19,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              height: 1.35,
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              label: 'Tin cậy: ${result.confidence.labelVi}',
              color: switch (result.confidence) {
                ConfidenceLevel.high => AppColors.success,
                ConfidenceLevel.medium => AppColors.accent,
                ConfidenceLevel.low => AppColors.secondaryText,
                ConfidenceLevel.conflict => AppColors.error,
              },
            ),
            _Chip(
              label: knowledgeLabel,
              color: result.fromImportedKnowledge
                  ? AppColors.success
                  : AppColors.secondaryText,
            ),
          ],
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...notes.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                w,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Giải thích',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
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
              icon: const Icon(Icons.menu_book_outlined, size: 18),
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
          child: FilledButton(
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
            child: const Text('Lưu vào môn học'),
          ),
        ),
        if (onReset != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onReset,
              child: const Text('Câu hỏi mới'),
            ),
          ),
        ],
        PopupMenuButton<_ResultMoreAction>(
          tooltip: 'Thêm',
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
                        content: Text('Đã ghi nhận kết quả sai.'),
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
          icon: const Icon(Icons.more_horiz),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
