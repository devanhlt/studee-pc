import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/data/mathpix/mathpix_config.dart';
import 'package:studee_pc/data/mathpix/mathpix_credentials.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';

/// Low-level Mathpix HTTP client.
///
/// Speaks Mathpix `/v3/text` and `/v3/pdf`. Point [MathpixCredentials.baseUrl]
/// at a middleware later if it proxies the same paths and JSON shapes.
class MathpixClient {
  MathpixClient({
    required CredentialsRepository credentials,
    http.Client? httpClient,
    this.pdfPollInterval = MathpixConfig.pdfPollInterval,
    this.pdfPollTimeout = MathpixConfig.pdfPollTimeout,
  })  : _credentials = credentials,
        _http = httpClient ?? http.Client();

  final CredentialsRepository _credentials;
  final http.Client _http;
  final Duration pdfPollInterval;
  final Duration pdfPollTimeout;
  final AppLogger _log = AppLogger('MathpixClient');

  Future<MathpixCredentials> loadCredentials() async {
    final envId = Platform.environment['MATHPIX_APP_ID']?.trim();
    final envKey = Platform.environment['MATHPIX_APP_KEY']?.trim();
    final envUrl = Platform.environment['MATHPIX_BASE_URL']?.trim();

    final stored = await _credentials.loadAll();
    final appId = (envId != null && envId.isNotEmpty)
        ? envId
        : stored.mathpixAppId;
    final appKey = (envKey != null && envKey.isNotEmpty)
        ? envKey
        : stored.mathpixAppKey;
    final baseUrl = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : stored.mathpixBaseUrl;

    if (appId == null ||
        appId.isEmpty ||
        appKey == null ||
        appKey.isEmpty) {
      throw const MissingApiKeyFailure(
        userMessage:
            'Nhập Mathpix app_id và app_key trong Cài đặt (hoặc biến môi trường MATHPIX_APP_ID / MATHPIX_APP_KEY).',
        code: 'mathpix_credentials_missing',
      );
    }

    return MathpixCredentials(
      appId: appId,
      appKey: appKey,
      baseUrl: (baseUrl == null || baseUrl.isEmpty)
          ? MathpixConfig.defaultBaseUrl
          : baseUrl,
    );
  }

  Map<String, String> _headers(MathpixCredentials creds) => {
        'app_id': creds.appId,
        'app_key': creds.appKey,
      };

  /// Connectivity probe — validates app_id/app_key without OCR content.
  ///
  /// Uses GET /v3/ocr-usage (not a blank image). A blank PNG returns
  /// Mathpix error "Content not found", which is not an auth failure.
  Future<void> testConnection() async {
    final creds = await loadCredentials();
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 1));
    final uri = creds.resolve(MathpixConfig.usagePath).replace(
      queryParameters: {
        'group_by': 'usage_type',
        'timespan': 'day',
        'from_date': from.toIso8601String(),
        'to_date': now.toIso8601String(),
      },
    );

    final response = await _http
        .get(uri, headers: _headers(creds))
        .timeout(MathpixConfig.httpTimeout);

    // Reuse status decoding (401/403 → missing key, etc.).
    _decodeObject(response);
    _log.info('Mathpix connection OK');
  }

  Future<MathpixTextResult> recognizeImageFile({
    required MathpixCredentials creds,
    required String imagePath,
  }) async {
    // Prefer multipart file upload (Mathpix image-OCR guide).
    return recognizeImageMultipart(
      creds: creds,
      imagePath: imagePath,
    );
  }

  /// Shared options for POST /v3/text (image OCR guide).
  ///
  /// [enable_document_layout] is required for full-page screenshots / exam
  /// pages; without it Mathpix uses snippet-oriented recognition.
  static Map<String, dynamic> imageOcrOptions() => {
        'math_inline_delimiters': MathpixConfig.mathInlineDelimiters,
        'math_display_delimiters': MathpixConfig.mathDisplayDelimiters,
        'rm_spaces': true,
        'enable_document_layout': true,
        // Prefer ``` fences over lstlisting for our Markdown renderer.
        'disable_lstlisting': true,
        // Plain list markers instead of LaTeX itemize.
        'disable_itemize': true,
        // Skip headers/footers/QR crops for study screenshots.
        'include_page_info': false,
        'metadata': {'improve_mathpix': false},
      };

  Future<MathpixTextResult> recognizeImageBase64({
    required MathpixCredentials creds,
    required String mimeType,
    required String base64Data,
  }) async {
    final uri = creds.resolve(MathpixConfig.textPath);
    final body = {
      'src': 'data:$mimeType;base64,$base64Data',
      ...imageOcrOptions(),
    };

    final response = await _http
        .post(
          uri,
          headers: {
            ..._headers(creds),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(MathpixConfig.httpTimeout);

    return _parseTextResponse(response);
  }

  Future<MathpixTextResult> recognizeImageMultipart({
    required MathpixCredentials creds,
    required String imagePath,
  }) async {
    final uri = creds.resolve(MathpixConfig.textPath);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(creds));
    // Guide: all options go in stringified `options_json` with the file.
    request.fields['options_json'] = jsonEncode(imageOcrOptions());
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamed = await _http
        .send(request)
        .timeout(MathpixConfig.httpTimeout);
    final response = await http.Response.fromStream(streamed);
    return _parseTextResponse(response);
  }

  /// Upload a PDF and return the Mathpix `pdf_id`.
  Future<String> submitPdf({
    required MathpixCredentials creds,
    required String pdfPath,
    List<int>? pages,
  }) async {
    final uri = creds.resolve(MathpixConfig.pdfPath);
    final options = <String, dynamic>{
      'math_inline_delimiters': MathpixConfig.mathInlineDelimiters,
      'math_display_delimiters': MathpixConfig.mathDisplayDelimiters,
      'rm_spaces': true,
      'include_page_breaks': true,
      'metadata': {'improve_mathpix': false},
    };
    final ranges = _pageRanges(pages);
    if (ranges != null) {
      options['page_ranges'] = ranges;
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(creds));
    request.fields['options_json'] = jsonEncode(options);
    request.files.add(await http.MultipartFile.fromPath('file', pdfPath));

    final streamed = await _http
        .send(request)
        .timeout(MathpixConfig.httpTimeout);
    final response = await http.Response.fromStream(streamed);
    final map = _decodeObject(response);
    final pdfId = map['pdf_id'] as String?;
    if (pdfId == null || pdfId.isEmpty) {
      final err = map['error'] as String? ??
          map['error_info']?.toString() ??
          'missing pdf_id';
      throw OcrFailure(
        userMessage: 'Mathpix không nhận PDF: $err',
        code: 'mathpix_pdf_submit_failed',
      );
    }
    return pdfId;
  }

  /// Poll until `status` is completed/error. Yields progress snapshots.
  Stream<MathpixPdfStatus> pollPdfStatus({
    required MathpixCredentials creds,
    required String pdfId,
    required bool Function() isCancelled,
  }) async* {
    final uri = creds.resolve('${MathpixConfig.pdfPath}/$pdfId');
    final deadline = DateTime.now().add(pdfPollTimeout);

    while (true) {
      if (isCancelled()) {
        throw const CancelledFailure(code: 'cancelled');
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const OcrFailure(
          userMessage: 'Mathpix xử lý PDF quá lâu. Thử lại sau.',
          code: 'mathpix_pdf_timeout',
        );
      }

      final response = await _http
          .get(uri, headers: _headers(creds))
          .timeout(MathpixConfig.httpTimeout);
      final map = _decodeObject(response);
      final status = MathpixPdfStatus.fromJson(map);
      yield status;

      if (status.status == 'completed' || status.status == 'error') {
        return;
      }

      await Future<void>.delayed(pdfPollInterval);
    }
  }

  Future<String> downloadPdfMmd({
    required MathpixCredentials creds,
    required String pdfId,
  }) async {
    final uri = creds.resolve('${MathpixConfig.pdfPath}/$pdfId.mmd');
    final response = await _http
        .get(uri, headers: _headers(creds))
        .timeout(MathpixConfig.httpTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OcrFailure(
        userMessage:
            'Không tải được kết quả Mathpix (HTTP ${response.statusCode}).',
        code: 'mathpix_pdf_download_failed',
      );
    }
    return response.body;
  }

  MathpixTextResult _parseTextResponse(http.Response response) {
    final map = _decodeObject(response);
    final error = map['error'] as String?;
    if (error != null && error.isNotEmpty) {
      return MathpixTextResult(
        text: '',
        confidence: 0,
        error: error,
        raw: map,
      );
    }
    final text = (map['text'] as String?) ?? '';
    final confidence = (map['confidence_rate'] as num?)?.toDouble() ??
        (map['confidence'] as num?)?.toDouble() ??
        0.9;
    return MathpixTextResult(
      text: text,
      confidence: confidence.clamp(0.0, 1.0),
      raw: map,
    );
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw FormatException('expected object');
      }
      map = Map<String, dynamic>.from(decoded);
    } on Object {
      throw OcrFailure(
        userMessage:
            'Mathpix trả về dữ liệu không hợp lệ (HTTP ${response.statusCode}).',
        code: 'mathpix_bad_response',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MissingApiKeyFailure(
        userMessage:
            'Mathpix từ chối khóa (app_id/app_key). Kiểm tra lại trong Cài đặt.',
        code: 'mathpix_unauthorized',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = map['error'] as String? ??
          map['error_info']?.toString() ??
          'HTTP ${response.statusCode}';
      throw OcrFailure(
        userMessage: 'Mathpix lỗi: $err',
        code: 'mathpix_http_${response.statusCode}',
      );
    }
    return map;
  }

  static String? _pageRanges(List<int>? pages) {
    if (pages == null || pages.isEmpty) return null;
    final sorted = [...pages]..sort();
    return sorted.join(',');
  }
}

class MathpixTextResult {
  const MathpixTextResult({
    required this.text,
    required this.confidence,
    this.error,
    this.raw = const {},
  });

  final String text;
  final double confidence;
  final String? error;
  final Map<String, dynamic> raw;
}

class MathpixPdfStatus {
  const MathpixPdfStatus({
    required this.status,
    this.numPages,
    this.numPagesCompleted,
    this.percentDone,
    this.error,
  });

  factory MathpixPdfStatus.fromJson(Map<String, dynamic> map) {
    return MathpixPdfStatus(
      status: (map['status'] as String?) ?? 'unknown',
      numPages: (map['num_pages'] as num?)?.toInt(),
      numPagesCompleted: (map['num_pages_completed'] as num?)?.toInt(),
      percentDone: (map['percent_done'] as num?)?.toDouble(),
      error: map['error'] as String?,
    );
  }

  final String status;
  final int? numPages;
  final int? numPagesCompleted;
  final double? percentDone;
  final String? error;
}
