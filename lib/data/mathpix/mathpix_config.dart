/// Mathpix OCR HTTP configuration.
///
/// Default [baseUrl] talks to Mathpix directly. Later a middleware backend can
/// expose the same `/v3/text` and `/v3/pdf` paths (or be swapped via settings).
abstract final class MathpixConfig {
  static const String defaultBaseUrl = 'https://api.mathpix.com';

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
