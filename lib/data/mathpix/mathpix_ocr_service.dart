import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/data/mathpix/mathpix_client.dart';
import 'package:studee_pc/data/mathpix/mathpix_credentials.dart';
import 'package:studee_pc/data/mathpix/mathpix_text_normalizer.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';

/// OCR via Mathpix API, implementing the same [OcrService] event contract
/// used by ingestion / solve (page JSON files + streaming events).
///
/// Set [MathpixClient] `baseUrl` (via credentials) to a middleware later
/// without changing this surface.
class MathpixOcrService implements OcrService {
  MathpixOcrService({
    required MathpixClient client,
    bool forceMock = false,
  })  : _client = client,
        _forceMock = forceMock;

  final MathpixClient _client;
  final bool _forceMock;
  final AppLogger _log = AppLogger('MathpixOcrService');
  final Map<String, Completer<void>> _cancelSignals = {};

  @override
  Stream<OcrEvent> process(OcrRequest request) async* {
    final cancel = Completer<void>();
    _cancelSignals[request.jobId] = cancel;
    bool isCancelled() => cancel.isCompleted;

    try {
      await Directory(request.outputDirectory).create(recursive: true);

      if (_forceMock) {
        yield* _runMock(request);
        return;
      }

      yield OcrProgressEvent(
        jobId: request.jobId,
        page: 1,
        totalPages: 1,
        stage: 'starting',
      );

      final creds = await _client.loadCredentials();
      final action = request.action;
      final lower = request.inputPath.toLowerCase();
      final isPdf = action == 'parse_document' || lower.endsWith('.pdf');

      if (isPdf) {
        yield* _processPdf(request, creds: creds, isCancelled: isCancelled);
      } else {
        yield* _processImage(request, creds: creds, isCancelled: isCancelled);
      }
    } on CancelledFailure {
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: 'cancelled',
        message: 'Đã hủy OCR.',
      );
    } on AppFailure catch (f) {
      _log.warning('Mathpix OCR failed code=${f.code}');
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: f.code ?? 'mathpix_failed',
        message: f.userMessage,
      );
    } on Object catch (e) {
      _log.severe('Mathpix OCR unexpected error', e);
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: 'mathpix_unexpected',
        message: 'OCR Mathpix thất bại. Thử lại hoặc kiểm tra Cài đặt.',
      );
    } finally {
      _cancelSignals.remove(request.jobId);
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final c = _cancelSignals[jobId];
    if (c != null && !c.isCompleted) {
      c.complete();
      _log.info('Cancelled Mathpix OCR job id=$jobId');
    }
  }

  Stream<OcrEvent> _processImage(
    OcrRequest request, {
    required MathpixCredentials creds,
    required bool Function() isCancelled,
  }) async* {
    if (isCancelled()) {
      throw const CancelledFailure(code: 'cancelled');
    }

    yield OcrProgressEvent(
      jobId: request.jobId,
      page: 1,
      totalPages: 1,
      stage: 'ocr',
    );

    final result = await _client.recognizeImageFile(
      creds: creds,
      imagePath: request.inputPath,
    );

    if (isCancelled()) {
      throw const CancelledFailure(code: 'cancelled');
    }

    if (result.error != null && result.error!.isNotEmpty) {
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: 'mathpix_image_error',
        message: result.error,
      );
      return;
    }

    final rawText = result.text;
    final normalized = MathpixTextNormalizer.normalize(rawText);
    _log.info(
      'OCR image text rawLen=${rawText.length} normLen=${normalized.length} '
      'pmatrix=${RegExp(r'\\begin\{pmatrix\}').allMatches(normalized).length} '
      'confidence=${result.confidence}',
    );
    // Debug snippet (truncated, no secrets) — helps verify A/B matrix split.
    final snip = normalized.length <= 240
        ? normalized
        : '${normalized.substring(0, 240)}…';
    _log.info('OCR normalized snip: ${snip.replaceAll('\n', r'\n')}');

    final pagePath = await _writePageJson(
      outputDirectory: request.outputDirectory,
      page: 1,
      text: normalized,
      rawText: rawText,
      confidence: result.confidence,
      raw: result.raw,
      method: 'mathpix_v3_text',
    );

    yield OcrPageCompletedEvent(
      jobId: request.jobId,
      page: 1,
      resultPath: pagePath,
    );
    yield OcrCompletedEvent(jobId: request.jobId);
  }

  Stream<OcrEvent> _processPdf(
    OcrRequest request, {
    required MathpixCredentials creds,
    required bool Function() isCancelled,
  }) async* {
    yield OcrProgressEvent(
      jobId: request.jobId,
      page: 0,
      totalPages: 0,
      stage: 'upload',
    );

    final pdfId = await _client.submitPdf(
      creds: creds,
      pdfPath: request.inputPath,
      pages: request.pages,
    );
    _log.info('Mathpix PDF submitted');

    var totalPages = 0;
    await for (final status in _client.pollPdfStatus(
      creds: creds,
      pdfId: pdfId,
      isCancelled: isCancelled,
    )) {
      totalPages = status.numPages ?? totalPages;
      final done = status.numPagesCompleted ?? 0;
      yield OcrProgressEvent(
        jobId: request.jobId,
        page: done.clamp(0, totalPages > 0 ? totalPages : done),
        totalPages: totalPages > 0 ? totalPages : (done > 0 ? done : 1),
        stage: status.status,
      );

      if (status.status == 'error') {
        yield OcrFailedEvent(
          jobId: request.jobId,
          code: 'mathpix_pdf_error',
          message: status.error ?? 'Mathpix xử lý PDF thất bại.',
        );
        return;
      }
    }

    if (isCancelled()) {
      throw const CancelledFailure(code: 'cancelled');
    }

    yield OcrProgressEvent(
      jobId: request.jobId,
      page: totalPages,
      totalPages: totalPages > 0 ? totalPages : 1,
      stage: 'download',
    );

    final mmd = await _client.downloadPdfMmd(creds: creds, pdfId: pdfId);
    final pages = _splitMmdPages(mmd);
    if (pages.isEmpty) {
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: 'mathpix_pdf_empty',
        message: 'Mathpix không trả về văn bản từ PDF.',
      );
      return;
    }

    totalPages = pages.length;
    for (var i = 0; i < pages.length; i++) {
      if (isCancelled()) {
        throw const CancelledFailure(code: 'cancelled');
      }
      final pageNum = i + 1;
      final text = pages[i];
      final pagePath = await _writePageJson(
        outputDirectory: request.outputDirectory,
        page: pageNum,
        text: MathpixTextNormalizer.normalize(text),
        confidence: text.trim().isEmpty ? 0.4 : 0.9,
        raw: {'pdf_id': pdfId, 'page': pageNum},
        method: 'mathpix_v3_pdf',
      );
      yield OcrProgressEvent(
        jobId: request.jobId,
        page: pageNum,
        totalPages: totalPages,
        stage: 'ocr',
      );
      yield OcrPageCompletedEvent(
        jobId: request.jobId,
        page: pageNum,
        resultPath: pagePath,
      );
    }

    yield OcrCompletedEvent(jobId: request.jobId);
  }

  Stream<OcrEvent> _runMock(OcrRequest request) async* {
    yield OcrProgressEvent(
      jobId: request.jobId,
      page: 1,
      totalPages: 1,
      stage: 'mock',
    );
    final pagePath = await _writePageJson(
      outputDirectory: request.outputDirectory,
      page: 1,
      text: 'Mock OCR text for ${p.basename(request.inputPath)}',
      confidence: 0.99,
      raw: const {'mock': true},
      method: 'mock',
      mock: true,
    );
    yield OcrPageCompletedEvent(
      jobId: request.jobId,
      page: 1,
      resultPath: pagePath,
    );
    yield OcrCompletedEvent(jobId: request.jobId);
  }

  /// Split Mathpix MMD on `\pagebreak` markers (include_page_breaks: true).
  static List<String> _splitMmdPages(String mmd) {
    final normalized = mmd.replaceAll('\r\n', '\n');
    // Mathpix emits `\pagebreak` (LaTeX) between pages.
    final parts = normalized.split(RegExp(r'\\pagebreak\s*'));
    final pages = parts.map((e) => e.trim()).toList();
    // Drop a trailing empty segment after a final pagebreak.
    while (pages.isNotEmpty && pages.last.isEmpty) {
      pages.removeLast();
    }
    if (pages.isEmpty && normalized.trim().isNotEmpty) {
      return [normalized.trim()];
    }
    return pages;
  }

  Future<String> _writePageJson({
    required String outputDirectory,
    required int page,
    required String text,
    required double confidence,
    required Map<String, dynamic> raw,
    required String method,
    String? rawText,
    bool mock = false,
  }) async {
    final fileName = 'page_${page.toString().padLeft(4, '0')}.json';
    final file = File(p.join(outputDirectory, fileName));
    final payload = {
      'page': page,
      'status': 'completed',
      'method': method,
      'text': text,
      'normalized_text': text,
      if (rawText != null) 'raw_text': rawText,
      'blocks': <Map<String, dynamic>>[],
      'bbox': <Map<String, dynamic>>[],
      'confidence': confidence,
      'engine': mock ? 'mock' : 'mathpix',
      'model_name': 'mathpix',
      'model_version': 'v3',
      'mock': mock,
      'raw': raw,
      'metadata': {
        'method': method,
        'provider': 'mathpix',
      },
    };
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
      flush: true,
    );
    return fileName;
  }
}
