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
    });
  }

  @override
  void dispose() {
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
    setState(() => _starting = true);
    final r = await _service.startFromImage(
      subjectId: widget.subjectId,
      bytes: file!.bytes!,
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

  Future<void> _pasteText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán văn bản'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Dán nội dung tài liệu tại đây…',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (text == null) return;
    setState(() => _starting = true);
    final r = await _service.startFromPastedText(
      subjectId: widget.subjectId,
      text: text,
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
    setState(() => _starting = true);
    final r = await _service.startFromPdf(
      subjectId: widget.subjectId,
      bytes: Uint8List.fromList(file!.bytes!),
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
    _service.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(ingestionStateProvider);
    final state = asyncState.asData?.value ?? _service.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập kiến thức'),
        actions: [
          if (state != null && !state.status.isTerminal)
            TextButton(
              onPressed: () => _service.cancel(),
              child: const Text('Hủy'),
            ),
        ],
      ),
      body: state == null || state.status == IngestionJobStatus.queued
          ? _SourceChooser(
              busy: _starting,
              onImage: _pickImage,
              onScreenshot: _capture,
              onPaste: _pasteText,
              onPdf: _pickPdf,
            )
          : _IngestionBody(
              state: state,
              pageControllers: _pageControllers,
              onSubmitText: () => _submitTextReview(state),
              onSubmitStructure: () => _submitStructure(state),
              onRestart: _startAnotherImport,
              onImportAnother: _startAnotherImport,
            ),
    );
  }
}

class _SourceChooser extends StatelessWidget {
  const _SourceChooser({
    required this.busy,
    required this.onImage,
    required this.onScreenshot,
    required this.onPaste,
    required this.onPdf,
  });

  final bool busy;
  final VoidCallback onImage;
  final VoidCallback onScreenshot;
  final VoidCallback onPaste;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppLayout.pageInsets(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn nguồn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ảnh, ảnh chụp màn hình, văn bản dán hoặc PDF.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          if (busy) const LinearProgressIndicator(),
          if (busy) const SizedBox(height: 12),
          _SourceTile(
            icon: Icons.image_outlined,
            label: 'Ảnh',
            onTap: busy ? null : onImage,
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.crop_free,
            label: 'Ảnh chụp màn hình',
            onTap: busy ? null : onScreenshot,
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.content_paste,
            label: 'Dán văn bản',
            onTap: busy ? null : onPaste,
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            onTap: busy ? null : onPdf,
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
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
                'Đơn vị kiến thức',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (units.isEmpty)
                const Text(
                  'Không có đơn vị kiến thức.',
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
