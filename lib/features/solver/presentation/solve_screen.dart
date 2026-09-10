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
import 'package:studee_pc/core/utils/answer_display.dart';
import 'package:studee_pc/core/utils/user_facing_copy.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/entities/solve_result.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
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
            const SnackBar(content: Text('Đã hủy chọn vùng.')),
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

  void _beginSolveAgain() {
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
    if (!await _ensureApiKey()) return;
    setState(() => _busy = true);
    final result = await _service.solveFromText(
      subjectId: widget.subjectId,
      text: _textController.text,
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

    final showInputForm = state.result == null &&
        !state.needsOcrReview &&
        !state.needsQuestionConfirm;

    final Widget body;
    if (showInputForm) {
      body = Padding(
        padding: AppLayout.pageInsets(context),
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
            const SizedBox(height: 4),
            const Text(
              'Dán đề, chọn ảnh, hoặc chụp màn hình.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.35,
              ),
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _solveText,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppShortcuts.label('Giải', 'G')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Chọn ảnh',
                  onPressed: _busy ? null : _solveImage,
                  icon: const Icon(Icons.image_outlined),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  tooltip: 'Chụp màn hình',
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.crop_free),
                ),
              ],
            ),
            if (_busy || state.stage.isInProgress) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                state.stage.labelVi,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
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
                style: const TextStyle(color: AppColors.secondaryText),
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
              'Chữ nhận dạng chưa rõ — hãy chỉnh lại trước khi giải:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ocrController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _continueOcr,
              child: Text(AppShortcuts.label('Tiếp tục giải', 'G')),
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
                  onPressed: _busy ? null : _confirmQuestionAndSolve,
                  child: Text(AppShortcuts.label('Xác nhận và giải', 'G')),
                ),
                TextButton(
                  onPressed: _busy ? null : _newQuestion,
                  child: const Text('Câu hỏi mới'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (_busy || state.stage.isInProgress) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              state.stage.labelVi,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
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
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
          if (state.result != null) ...[
            if (state.rawText != null &&
                state.rawText!.trim().isNotEmpty) ...[
              CollapsedQuestionTile(text: state.rawText!),
              const SizedBox(height: 12),
            ],
            SolveResultView(
              result: state.result!,
              subjectId: widget.subjectId,
              onSolveAgain: _beginSolveAgain,
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
                } else if (state.needsQuestionConfirm) {
                  _confirmQuestionAndSolve();
                } else if (showInputForm) {
                  _solveText();
                }
              },
              AppShortcuts.activator(LogicalKeyboardKey.enter): () {
                if (_busy) return;
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

/// Collapsed question preview — tap to expand full text / markdown.
class CollapsedQuestionTile extends StatelessWidget {
  const CollapsedQuestionTile({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
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
  });

  final SolveResult result;
  final String subjectId;
  final VoidCallback? onSolveAgain;
  final VoidCallback? onReset;
  final bool compact;

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

    final column = Column(
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
        const SizedBox(height: 16),
        Row(
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
        ),
      ],
    );

    return column;
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
