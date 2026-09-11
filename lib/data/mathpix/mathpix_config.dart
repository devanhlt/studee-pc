import 'package:studee_pc/data/backend/backend_config.dart';

/// Mathpix-compatible OCR HTTP configuration (via Studee middleware).
abstract final class MathpixConfig {
  static String get defaultBaseUrl => BackendConfig.baseUrl;

  static const String usagePath = '/v3/ocr-usage';
  static const String textPath = '/v3/text';
  static const String pdfPath = '/v3/pdf';

  /// Prefer `$…$` / `$$…$$` so StudyMarkdown renders without extra conversion.
  static const List<String> mathInlineDelimiters = ['\$', '\$'];
  static const List<String> mathDisplayDelimiters = ['\$\$', '\$\$'];

  static const Duration httpTimeout = Duration(seconds: 60);
  static const Duration pdfPollInterval = Duration(seconds: 2);
  static const Duration pdfPollTimeout = Duration(minutes: 10);
}
