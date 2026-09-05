import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/widgets/app_shortcuts.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/entities/solve_result.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
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
  /// ⌘G / ⌘↵ for Giải — only while the Giải tab is selected.
  final bool shortcutsActive;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  final _textController = TextEditingController();
  final _ocrController = TextEditingController();
  bool _busy = false;

  SolveService get _service => ref.read(solveServiceProvider);

  @override
  void dispose() {
    _textController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  Future<bool> _ensureApiKey() async {
    if (await _service.hasApiKey()) {
      final store = ref.read(privacyConsentStoreProvider);
      return ensureDeepSeekPrivacyConsent(context, store: store);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập khóa API DeepSeek')),
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
    // Text solve calls DeepSeek immediately.
    if (!await _ensureApiKey()) return;
    setState(() => _busy = true);
    final result = await _service.solveFromText(
      subjectId: widget.subjectId,
      text: _textController.text,
    );
    setState(() => _busy = false);
    _handle(result);
  }

  Future<void> _solveImage() async {
    if (!await _ensurePrivacy()) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    setState(() => _busy = true);
    final result = await _service.solveFromImage(
      subjectId: widget.subjectId,
      bytes: Uint8List.fromList(bytes),
    );
    setState(() => _busy = false);
    if (result is Failure &&
        result.failureOrNull?.code == 'ocr_review_required') {
      _ocrController.text = _service.current.rawText ?? '';
      return;
    }
    _handle(result);
  }

  Future<void> _capture() async {
    if (!await _ensurePrivacy()) return;
    setState(() => _busy = true);
    try {
      final captured =
          await ref.read(desktopIntegrationProvider).captureRegion();
      if (captured == null) {
        setState(() => _busy = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã hủy chọn vùng — hoặc quyền Ghi màn hình bị kẹt. '
                'Vào Cài đặt → Đặt lại quyền Ghi màn hình, thoát app rồi mở lại.',
              ),
            ),
          );
        }
        return;
      }
      final result = await _service.solveFromImage(
        subjectId: widget.subjectId,
        bytes: captured.bytes,
        inputType: 'screenshot',
      );
      setState(() => _busy = false);
      if (result is Failure &&
          result.failureOrNull?.code == 'ocr_review_required') {
        _ocrController.text = _service.current.rawText ?? '';
        return;
      }
      _handle(result);
    } on ScreenCaptureFailure catch (f) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      }
    }
  }

  Future<void> _continueOcr() async {
    // Continuing after OCR review triggers DeepSeek.
    if (!await _ensureApiKey()) return;
    setState(() => _busy = true);
    final result = await _service.continueWithReviewedText(
      subjectId: widget.subjectId,
      reviewedText: _ocrController.text,
    );
    setState(() => _busy = false);
    _handle(result);
  }

  void _handle(Result<SolveResult> result) {
    result.when(
      success: (_) {
        ref.invalidate(subjectHistoryProvider(widget.subjectId));
      },
      failure: (f) {
        if (f is CancelledFailure || f.code == 'cancelled') return;
        if (f is MissingApiKeyFailure) context.push('/settings');
        if (f.code == 'ocr_review_required') return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  void _newQuestion() {
    _service.reset();
    _textController.clear();
    _ocrController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(solveStateProvider);
    final state = async.asData?.value ?? _service.current;

    final showInputForm =
        state.result == null && !state.needsOcrReview;

    final Widget body;
    if (showInputForm) {
      body = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedded &&
                (state.stage.isInProgress ||
                    state.stage == SolvePipelineStage.offlineFailure ||
                    state.stage == SolvePipelineStage.partialFailure))
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (state.stage.isInProgress)
                      TextButton(
                        onPressed: () async {
                          await _service.cancel();
                          if (mounted) setState(() => _busy = false);
                        },
                      child: const Text('Hủy'),
                      ),
                    if (state.stage == SolvePipelineStage.offlineFailure ||
                        state.stage == SolvePipelineStage.partialFailure)
                      TextButton(
                        onPressed: () {
                          _service.reset();
                          setState(() => _busy = false);
                        },
                        child: const Text('Đóng'),
                      ),
                  ],
                ),
              ),
            const Text(
              'Nhập câu hỏi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (!widget.shortcutsActive) return KeyEventResult.ignored;
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (_busy || !showInputForm) return KeyEventResult.ignored;
                  final mod = HardwareKeyboard.instance.isMetaPressed ||
                      HardwareKeyboard.instance.isControlPressed;
                  if (!mod) return KeyEventResult.ignored;
                  // ⌘G / ⌘↵ → Giải (works while typing in the field)
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.keyG) {
                    _solveText();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _textController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText:
                        'Dán nội dung câu hỏi… (${AppShortcuts.chord('G')} để giải)',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _solveText,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppShortcuts.label('Giải', 'G')),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _solveImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.crop_free),
                  label: const Text('Chụp màn hình'),
                ),
              ],
            ),
            if (_busy || state.stage.isInProgress) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(state.stage.labelVi),
            ],
            if (state.errorMessage != null &&
                state.result == null &&
                !state.stage.isInProgress) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  _service.reset();
                  setState(() => _busy = false);
                },
                child: const Text('Thử lại'),
              ),
            ],
            if (state.errorMessage != null &&
                state.result == null &&
                state.stage.isInProgress) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.warning),
              ),
            ],
          ],
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (widget.embedded &&
              (state.stage.isInProgress ||
                  state.stage == SolvePipelineStage.offlineFailure ||
                  state.stage == SolvePipelineStage.partialFailure)) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (state.stage.isInProgress)
                    TextButton(
                      onPressed: () async {
                        await _service.cancel();
                        if (mounted) setState(() => _busy = false);
                      },
                      child: const Text('Hủy'),
                    ),
                  if (state.stage == SolvePipelineStage.offlineFailure ||
                      state.stage == SolvePipelineStage.partialFailure)
                    TextButton(
                      onPressed: () {
                        _service.reset();
                        setState(() => _busy = false);
                      },
                      child: const Text('Đóng'),
                    ),
                ],
              ),
            ),
          ],
          if (state.needsOcrReview) ...[
            const Text(
              'Độ tin cậy OCR thấp — hãy chỉnh sửa văn bản:',
              style: TextStyle(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ocrController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Văn bản nhận dạng',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _continueOcr,
              child: Text(AppShortcuts.label('Tiếp tục giải', 'G')),
            ),
            const SizedBox(height: 24),
          ],
          if (_busy || state.stage.isInProgress) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(state.stage.labelVi),
          ],
          if (state.errorMessage != null &&
              state.result == null &&
              !state.stage.isInProgress) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _service.reset();
                setState(() => _busy = false);
              },
              child: const Text('Thử lại'),
            ),
          ],
          if (state.errorMessage != null &&
              state.result == null &&
              state.stage.isInProgress) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.warning),
            ),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 8),
            SolveResultView(
              result: state.result!,
              subjectId: widget.subjectId,
              onSolveAgain: () async {
                setState(() => _busy = true);
                await _service.resolveAgain(subjectId: widget.subjectId);
                setState(() => _busy = false);
              },
              onReset: _newQuestion,
            ),
          ],
        ],
      );
    }

    final wrapped = CallbackShortcuts(
      bindings: widget.shortcutsActive
          ? <ShortcutActivator, VoidCallback>{
              AppShortcuts.activator(LogicalKeyboardKey.keyG): () {
                if (_busy) return;
                if (state.needsOcrReview) {
                  _continueOcr();
                } else if (showInputForm) {
                  _solveText();
                }
              },
              AppShortcuts.activator(LogicalKeyboardKey.enter): () {
                if (_busy) return;
                if (state.needsOcrReview) {
                  _continueOcr();
                } else if (showInputForm) {
                  _solveText();
                }
              },
            }
          : const <ShortcutActivator, VoidCallback>{},
      child: Focus(
        autofocus: widget.shortcutsActive,
        child: body,
      ),
    );

    if (widget.embedded) return wrapped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải câu hỏi'),
        actions: [
          if (state.stage.isInProgress)
            TextButton(
              onPressed: () async {
                await _service.cancel();
                if (mounted) setState(() => _busy = false);
              },
              child: const Text('Hủy'),
            ),
          if (state.stage == SolvePipelineStage.offlineFailure ||
              state.stage == SolvePipelineStage.partialFailure)
            TextButton(
              onPressed: () {
                _service.reset();
                setState(() => _busy = false);
              },
              child: const Text('Đóng'),
            ),
        ],
      ),
      body: wrapped,
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
  });

  final SolveResult result;
  final String subjectId;
  final VoidCallback? onSolveAgain;
  final VoidCallback? onReset;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answer = [
      if (result.finalAnswerLabel != null) result.finalAnswerLabel,
      if (result.finalAnswerContent != null) result.finalAnswerContent,
      if (result.shortAnswer != null &&
          result.shortAnswer != result.finalAnswerLabel)
        result.shortAnswer,
    ].whereType<String>().toSet().join(' — ');

    final knowledgeLabel = result.fromImportedKnowledge
        ? 'Từ kiến thức đã nhập'
        : 'Sinh từ kiến thức của mô hình';

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (answer.isEmpty)
          Text(
            '(Không có đáp án ngắn)',
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          )
        else
          StudyMarkdown(
            answer,
            compact: compact,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              height: 1.35,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              label: 'Tin cậy: ${result.confidence.labelVi}',
              color: switch (result.confidence) {
                ConfidenceLevel.high => AppColors.success,
                ConfidenceLevel.medium => AppColors.warning,
                ConfidenceLevel.low => AppColors.secondaryText,
                ConfidenceLevel.conflict => AppColors.error,
              },
            ),
            _Chip(
              label: knowledgeLabel,
              color: result.fromImportedKnowledge
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ],
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...result.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '⚠ $w',
                style: const TextStyle(color: AppColors.warning),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showReferencesPopup(
                context,
                result.references,
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(
                'Tham chiếu (${result.references.length})',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                final text = [
                  answer,
                  '',
                  result.explanationMarkdown,
                ].join('\n');
                await FlutterClipboard.copy(text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép.')),
                  );
                }
              },
              child: const Text('Sao chép'),
            ),
            OutlinedButton(
              onPressed: onSolveAgain,
              child: const Text('Giải lại'),
            ),
            OutlinedButton(
              onPressed: () async {
                final resultSvc = ref.read(solveServiceProvider);
                final r = await resultSvc.markIncorrect(
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
              },
              child: const Text('Kết quả sai'),
            ),
            FilledButton(
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
            if (onReset != null)
              TextButton(
                onPressed: onReset,
                child: const Text('Câu hỏi mới'),
              ),
          ],
        ),
      ],
    );

    return column;
  }
}

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
