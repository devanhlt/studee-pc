import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/enums/ingestion_job_status.dart';
import 'package:studee_pc/domain/enums/source_type.dart';
import 'package:studee_pc/features/ingestion/application/ingestion_service.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/solver/presentation/mobile_image_crop.dart';
import 'package:studee_pc/features/solver/presentation/scan_question_screen.dart';

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
        const SnackBar(content: Text('Hãy nhập mã kích hoạt để dùng Trợ lý Stud.')),
      );
      context.push('/settings');
      return false;
    }
    if (!mounted) return false;
    final store = ref.read(privacyConsentStoreProvider);
    return ensureDeepSeekPrivacyConsent(context, store: store);
  }

  Future<void> _pickImage() async {
    try {
      final captured = await captureAndCropImage(
        context,
        capture: () => ref.read(platformIntegrationProvider).pickImage(),
        emptyMessage: 'Tệp không có nội dung. Hãy chọn file khác.',
      );
      if (captured == null) return;
      setState(() => _starting = true);
      final r = await _service.startFromImage(
        subjectId: widget.subjectId,
        bytes: captured.bytes,
        fileName: captured.mimeType == 'image/jpeg' ? 'image.jpg' : 'image.png',
        type: SourceType.image,
      );
      setState(() => _starting = false);
      _handleStart(r);
    } on AppFailure catch (f) {
      setState(() => _starting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      }
    }
  }

  Future<void> _capture() async {
    setState(() => _starting = true);
    final platform = ref.read(platformIntegrationProvider);
    try {
      final captured = await platform.captureRegion();
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
            const SnackBar(content: Text('Ảnh chụp không có nội dung. Thử lại nhé.')),
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
    } on AppFailure catch (f) {
      setState(() => _starting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      setState(() => _starting = true);
      final captured = await ScanQuestionScreen.open(context);
      if (captured == null) {
        setState(() => _starting = false);
        return;
      }
      final r = await _service.startFromImage(
        subjectId: widget.subjectId,
        bytes: captured.bytes,
        fileName: 'camera.jpg',
        type: SourceType.image,
      );
      setState(() => _starting = false);
      _handleStart(r);
    } on AppFailure catch (f) {
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
        const SnackBar(content: Text('Hãy nhập nội dung.')),
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tệp không có nội dung. Hãy chọn file khác.')),
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
        const SnackBar(content: Text('Hãy nhập nội dung cho trang này.')),
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
          content: Text('Hãy chọn ít nhất một mục kiến thức hoặc câu hỏi để lưu.'),
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

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Nhập kiến thức',
        subtitle: choosingSource ? 'Dán văn bản hoặc chọn nguồn' : null,
        actions: [
          if (choosingSource) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                  case _SourceMoreAction.camera:
                    _captureFromCamera();
                  case _SourceMoreAction.pdf:
                    _pickPdf();
                }
              },
              itemBuilder: (_) {
                final platform = ref.read(platformIntegrationProvider);
                return [
                  const PopupMenuItem(
                    value: _SourceMoreAction.image,
                    child: Text('Ảnh'),
                  ),
                  if (platform.supportsScreenCapture)
                    const PopupMenuItem(
                      value: _SourceMoreAction.screenshot,
                      child: Text('Ảnh chụp màn hình'),
                    ),
                  if (platform.supportsCamera)
                    const PopupMenuItem(
                      value: _SourceMoreAction.camera,
                      child: Text('Quét câu hỏi'),
                    ),
                  const PopupMenuItem(
                    value: _SourceMoreAction.pdf,
                    child: Text('PDF'),
                  ),
                ];
              },
              icon: const Icon(AppIcons.more),
            ),
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

enum _SourceMoreAction { image, screenshot, camera, pdf }

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
            child: StudeeGlass(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
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
                  hintText: 'Dán tài liệu vào đây, càng đầy đủ thì đáp án càng chính xác…',
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: false,
                  contentPadding: EdgeInsets.all(AppLayout.cardPadding),
                ),
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
                        AppIcons.checkCircle,
                        color: AppColors.success,
                        size: AppIcons.sizeEmptyState,
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
            IngestionJobStatus.failed || IngestionJobStatus.cancelled =>
              StudeeStatusState(
                icon: AppIcons.error,
                title: state.status.labelVi,
                message: state.errorMessage ?? 'Thử lại với nguồn khác.',
                actionLabel: 'Thử lại',
                onAction: onRestart,
              ),
            _ => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.pagePadding,
                      AppLayout.gapSm,
                      AppLayout.pagePadding,
                      0,
                    ),
                    child: Text(
                      state.progressMessage ?? state.status.labelVi,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ),
                  const Expanded(child: StudeeSkeletonList()),
                ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: StudeeGlass(
        borderRadius: AppLayout.radiusControl,
        padding: const EdgeInsets.all(12),
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
                value:
                    current == null ? null : (current / total).clamp(0.0, 1.0),
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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppLayout.pagePadding),
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
                    borderRadius: AppLayout.controlBorder,
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
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Văn bản trang ${page.pageNumber}',
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppLayout.gapLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      preview,
                      const SizedBox(height: AppLayout.gapMd),
                      textField,
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppLayout.gapLg),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Duyệt văn bản nhận dạng · trang ${page.pageNumber}',
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
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubmit,
              child: const Text('Cấu trúc hóa bằng Trợ lý Stud'),
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
