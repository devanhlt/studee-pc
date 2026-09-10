import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/enums/ingestion_job_status.dart';
import 'package:studee_pc/domain/enums/source_type.dart';
import 'package:studee_pc/features/ingestion/application/ingestion_service.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';

final ingestionStateProvider =
    StreamProvider.autoDispose<IngestionState?>((ref) {
  final service = ref.watch(ingestionServiceProvider);
  // Seed with current snapshot so reopening the screen after a completed
  // import (or reset) reflects immediately; then follow live updates.
  return Stream<IngestionState?>.multi((controller) {
    controller.add(service.current);
    final sub = service.states.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
  });
});

class IngestionScreen extends ConsumerStatefulWidget {
  const IngestionScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<IngestionScreen> createState() => _IngestionScreenState();
}

class _IngestionScreenState extends ConsumerState<IngestionScreen> {
  final Map<int, TextEditingController> _pageControllers = {};
  final _pasteController = TextEditingController();
  final _pasteFocus = FocusNode();
  bool _starting = false;

  IngestionService get _service => ref.read(ingestionServiceProvider);

  @override
  void initState() {
    super.initState();
    // Singleton service keeps the last job; clear terminal / other-subject
    // state so "Nhập kiến thức" can run again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearPageControllers();
      _service.prepareForSubject(widget.subjectId);
      setState(() {});
      _pasteFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pasteFocus.dispose();
    _pasteController.dispose();
    _clearPageControllers();
    super.dispose();
  }

  void _clearPageControllers() {
    for (final c in _pageControllers.values) {
      c.dispose();
    }
    _pageControllers.clear();
  }

  Future<bool> _ensureApiKey() async {
    final has = await _service.hasApiKey();
    if (!has && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập khóa API DeepSeek')),
      );
      context.push('/settings');
      return false;
    }
    if (!mounted) return false;
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tệp trống — hãy chọn file khác.')),
      );
      return;
    }
    setState(() => _starting = true);
    final r = await _service.startFromImage(
      subjectId: widget.subjectId,
      bytes: file.bytes!,
      fileName: file.name,
      type: SourceType.image,
    );
    setState(() => _starting = false);
    _handleStart(r);
  }

  Future<void> _capture() async {
    setState(() => _starting = true);
    final desktop = ref.read(desktopIntegrationProvider);
    try {
      final captured = await desktop.captureRegion();
      if (captured == null) {
        setState(() => _starting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy chọn vùng.')),
          );
        }
        return;
      }
      if (captured.bytes.isEmpty) {
        setState(() => _starting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ảnh chụp trống — thử lại.')),
          );
        }
        return;
      }
      final r = await _service.startFromImage(
        subjectId: widget.subjectId,
        bytes: captured.bytes,
        fileName: 'screenshot.png',
        type: SourceType.screenshot,
      );
      setState(() => _starting = false);
      _handleStart(r);
    } on ScreenCaptureFailure catch (f) {
      setState(() => _starting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      }
    }
  }

  Future<void> _startFromPastedText([String? text]) async {
    final value = (text ?? _pasteController.text).trim();
    if (value.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung không được trống.')),
      );
      return;
    }
    setState(() => _starting = true);
    final r = await _service.startFromPastedText(
      subjectId: widget.subjectId,
      text: value,
    );
    setState(() => _starting = false);
    _handleStart(r);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tệp trống — hãy chọn file khác.')),
      );
      return;
    }
    setState(() => _starting = true);
    final r = await _service.startFromPdf(
      subjectId: widget.subjectId,
      bytes: Uint8List.fromList(file.bytes!),
      fileName: file.name,
    );
    setState(() => _starting = false);
    _handleStart(r);
  }

  void _handleStart(Result<IngestionState> result) {
    result.when(
      success: (state) => _syncControllers(state),
      failure: (f) {
        if (f is MissingApiKeyFailure) {
          context.push('/settings');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  void _syncControllers(IngestionState state) {
    for (final page in state.pages) {
      _pageControllers.putIfAbsent(
        page.pageNumber,
        () => TextEditingController(text: page.text),
      );
      _pageControllers[page.pageNumber]!.text = page.text;
    }
  }

  Future<void> _submitTextReview(IngestionState state) async {
    // Keychain / API key only when DeepSeek structuring is triggered.
    if (!await _ensureApiKey()) return;
    final reviewed = state.pages
        .map(
          (p) => p.copyWith(
            text: _pageControllers[p.pageNumber]?.text ?? p.text,
          ),
        )
        .toList();
    if (reviewed.every((p) => p.text.trim().isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung trang không được trống.')),
      );
      return;
    }
    final result = await _service.submitTextReview(reviewed);
    result.when(
      success: (_) {},
      failure: (f) {
        if (f is MissingApiKeyFailure) context.push('/settings');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  Future<void> _submitStructure(IngestionState state) async {
    final hasSelection = state.draftUnits.any((u) => u.selected) ||
        state.draftQuestions.any((q) => q.selected);
    if (!hasSelection) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn ít nhất một mục kiến thức hoặc câu hỏi để lưu.'),
        ),
      );
      return;
    }
    final result = await _service.submitStructureReview(
      units: state.draftUnits,
      questions: state.draftQuestions,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        _clearPageControllers();
        _service.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kiến thức vào môn học.')),
        );
        context.pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  void _startAnotherImport() {
    _clearPageControllers();
    _pasteController.clear();
    _service.reset();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pasteFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(ingestionStateProvider);
    final state = asyncState.asData?.value ?? _service.current;
    final choosingSource =
        state == null || state.status == IngestionJobStatus.queued;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập kiến thức'),
        actions: [
          if (choosingSource) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton(
                onPressed: _starting ? null : () => _startFromPastedText(),
                child: const Text('Bắt đầu'),
              ),
            ),
            PopupMenuButton<_SourceMoreAction>(
              tooltip: 'Thêm nguồn',
              enabled: !_starting,
              onSelected: (action) {
                switch (action) {
                  case _SourceMoreAction.image:
                    _pickImage();
                  case _SourceMoreAction.screenshot:
                    _capture();
                  case _SourceMoreAction.pdf:
                    _pickPdf();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _SourceMoreAction.image,
                  child: Text('Ảnh'),
                ),
                PopupMenuItem(
                  value: _SourceMoreAction.screenshot,
                  child: Text('Ảnh chụp màn hình'),
                ),
                PopupMenuItem(
                  value: _SourceMoreAction.pdf,
                  child: Text('PDF'),
                ),
              ],
              icon: const Icon(Icons.more_horiz),
            ),
            const SizedBox(width: 4),
          ] else if (state != null && !state.status.isTerminal)
            TextButton(
              onPressed: () => _service.cancel(),
              child: const Text('Hủy'),
            ),
        ],
      ),
      body: choosingSource
          ? _SourceChooser(
              busy: _starting,
              controller: _pasteController,
              focusNode: _pasteFocus,
            )
          : _IngestionBody(
              state: state!,
              pageControllers: _pageControllers,
              onSubmitText: () => _submitTextReview(state),
              onSubmitStructure: () => _submitStructure(state),
              onRestart: _startAnotherImport,
              onImportAnother: _startAnotherImport,
            ),
    );
  }
}

enum _SourceMoreAction { image, screenshot, pdf }

class _SourceChooser extends StatelessWidget {
  const _SourceChooser({
    required this.busy,
    required this.controller,
    required this.focusNode,
  });

  final bool busy;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final insets = AppLayout.pageInsets(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) const LinearProgressIndicator(),
        Expanded(
          child: Padding(
            padding: insets,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              expands: true,
              maxLines: null,
              minLines: null,
              enabled: !busy,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Dán nội dung tài liệu tại đây…',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IngestionBody extends StatelessWidget {
  const _IngestionBody({
    required this.state,
    required this.pageControllers,
    required this.onSubmitText,
    required this.onSubmitStructure,
    required this.onRestart,
    required this.onImportAnother,
  });

  final IngestionState state;
  final Map<int, TextEditingController> pageControllers;
  final VoidCallback onSubmitText;
  final VoidCallback onSubmitStructure;
  final VoidCallback onRestart;
  final VoidCallback onImportAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressBanner(state: state),
        Expanded(
          child: switch (state.status) {
            IngestionJobStatus.awaitingTextReview => _TextReview(
                state: state,
                controllers: pageControllers,
                onSubmit: onSubmitText,
              ),
            IngestionJobStatus.awaitingStructureReview => _StructureReview(
                state: state,
                onSubmit: onSubmitStructure,
              ),
            IngestionJobStatus.completed ||
            IngestionJobStatus.partiallyCompleted =>
              Center(
                child: SingleChildScrollView(
                  padding: AppLayout.pageInsets(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(state.status.labelVi),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onImportAnother,
                        child: const Text('Nhập thêm'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          onImportAnother();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ),
              ),
            IngestionJobStatus.failed || IngestionJobStatus.cancelled => Center(
                child: SingleChildScrollView(
                  padding: AppLayout.pageInsets(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ?? state.status.labelVi,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: onRestart,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            _ => Center(
                child: SingleChildScrollView(
                  padding: AppLayout.pageInsets(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        state.progressMessage ?? state.status.labelVi,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          },
        ),
      ],
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.state});
  final IngestionState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalPages;
    final current = state.currentPage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.progressMessage ?? state.status.labelVi,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (total != null && total > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: current == null ? null : (current / total).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              'Trang ${current ?? 0}/$total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextReview extends StatelessWidget {
  const _TextReview({
    required this.state,
    required this.controllers,
    required this.onSubmit,
  });

  final IngestionState state;
  final Map<int, TextEditingController> controllers;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isPdf = state.sourceType == SourceType.pdf;
    final narrow = AppLayout.isNarrow(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.pages.length,
            itemBuilder: (_, i) {
              final page = state.pages[i];
              final controller = controllers.putIfAbsent(
                page.pageNumber,
                () => TextEditingController(text: page.text),
              );
              if (isPdf) {
                final preview = Container(
                  height: 160,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: page.imagePath != null
                      ? Image.file(
                          File(page.imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            'Trang ${page.pageNumber}\n(xem trước)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        )
                      : Text(
                          'Trang ${page.pageNumber}\n(ảnh xem trước)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                );
                final textField = TextField(
                  controller: controller,
                  maxLines: narrow ? 8 : 14,
                  decoration: InputDecoration(
                    labelText: 'Văn bản trang ${page.pageNumber}',
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            preview,
                            const SizedBox(height: 12),
                            textField,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: preview),
                            const SizedBox(width: 12),
                            Expanded(child: textField),
                          ],
                        ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Duyệt văn bản OCR — trang ${page.pageNumber}',
                    helperText: page.ocrConfidence != null
                        ? 'Độ tin cậy OCR: ${(page.ocrConfidence! * 100).toStringAsFixed(0)}%'
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubmit,
              child: const Text('Cấu trúc hóa bằng DeepSeek'),
            ),
          ),
        ),
      ],
    );
  }
}

class _StructureReview extends StatefulWidget {
  const _StructureReview({
    required this.state,
    required this.onSubmit,
  });

  final IngestionState state;
  final VoidCallback onSubmit;

  @override
  State<_StructureReview> createState() => _StructureReviewState();
}

class _StructureReviewState extends State<_StructureReview> {
  @override
  Widget build(BuildContext context) {
    final units = widget.state.draftUnits;
    final questions = widget.state.draftQuestions;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'Mục kiến thức',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (units.isEmpty)
                const Text(
                  'Chưa có mục kiến thức.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ...units.map(
                (u) => CheckboxListTile(
                  value: u.selected,
                  onChanged: (v) => setState(() => u.selected = v ?? false),
                  title: StudyMarkdown(
                    u.content,
                    compact: true,
                    maxLines: 5,
                  ),
                  subtitle: Text(u.type.labelVi),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Câu hỏi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (questions.isEmpty)
                const Text(
                  'Không có câu hỏi.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ...questions.map((q) {
                final related = units
                    .where((u) => q.relatedUnitIds.contains(u.id))
                    .toList();
                return CheckboxListTile(
                  value: q.selected,
                  onChanged: (v) => setState(() => q.selected = v ?? false),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StudyMarkdown(
                        q.content,
                        compact: true,
                        maxLines: 5,
                      ),
                      if (q.choices.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...q.choices.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: StudyMarkdown(
                              '${c['label'] ?? ''}. ${c['content'] ?? ''}',
                              compact: true,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if ((q.answerContent ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        StudyMarkdown(
                          'Đáp án${q.answerLabel != null ? ' ${q.answerLabel}' : ''}: ${q.answerContent}',
                          compact: true,
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if ((q.explanation ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        StudyMarkdown(
                          'Lời giải: ${q.explanation}',
                          compact: true,
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (related.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kiến thức liên quan: ${related.map((u) => u.type.labelVi).join(', ')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(q.questionType.labelVi),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onSubmit,
              child: const Text('Lưu vào môn học'),
            ),
          ),
        ),
      ],
    );
  }
}
