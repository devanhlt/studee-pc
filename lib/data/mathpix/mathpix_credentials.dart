import 'package:studee_pc/data/mathpix/mathpix_config.dart';

/// Resolved OCR credentials + endpoint (activation code as Bearer identity).
class MathpixCredentials {
  MathpixCredentials({
    required this.appId,
    required this.appKey,
    String? baseUrl,
  }) : baseUrl = (baseUrl == null || baseUrl.trim().isEmpty)
            ? MathpixConfig.defaultBaseUrl
            : baseUrl.trim();

  final String appId;
  final String appKey;
  final String baseUrl;

  bool get isComplete =>
      appId.trim().isNotEmpty && appKey.trim().isNotEmpty;

  Uri resolve(String path) {
    final root =
        baseUrl.trim().isEmpty ? MathpixConfig.defaultBaseUrl : baseUrl.trim();
    final normalized =
        root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalized$p');
  }
}
