/// Snapshot of all API credentials loaded in one Keychain read.
class StoredApiCredentials {
  const StoredApiCredentials({
    this.deepSeekApiKey,
    this.mathpixAppId,
    this.mathpixAppKey,
    this.mathpixBaseUrl,
  });

  final String? deepSeekApiKey;
  final String? mathpixAppId;
  final String? mathpixAppKey;
  final String? mathpixBaseUrl;

  bool get hasDeepSeekApiKey =>
      deepSeekApiKey != null && deepSeekApiKey!.isNotEmpty;

  bool get hasMathpixCredentials =>
      mathpixAppId != null &&
      mathpixAppId!.isNotEmpty &&
      mathpixAppKey != null &&
      mathpixAppKey!.isNotEmpty;

  bool get hasAny =>
      hasDeepSeekApiKey ||
      (mathpixAppId != null && mathpixAppId!.isNotEmpty) ||
      (mathpixAppKey != null && mathpixAppKey!.isNotEmpty) ||
      (mathpixBaseUrl != null && mathpixBaseUrl!.isNotEmpty);

  StoredApiCredentials copyWith({
    String? deepSeekApiKey,
    String? mathpixAppId,
    String? mathpixAppKey,
    String? mathpixBaseUrl,
    bool clearDeepSeek = false,
    bool clearMathpixAppId = false,
    bool clearMathpixAppKey = false,
    bool clearMathpixBaseUrl = false,
    bool clearMathpix = false,
  }) {
    return StoredApiCredentials(
      deepSeekApiKey: clearDeepSeek
          ? null
          : (deepSeekApiKey ?? this.deepSeekApiKey),
      mathpixAppId: clearMathpix || clearMathpixAppId
          ? null
          : (mathpixAppId ?? this.mathpixAppId),
      mathpixAppKey: clearMathpix || clearMathpixAppKey
          ? null
          : (mathpixAppKey ?? this.mathpixAppKey),
      mathpixBaseUrl: clearMathpix || clearMathpixBaseUrl
          ? null
          : (mathpixBaseUrl ?? this.mathpixBaseUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        if (deepSeekApiKey != null) 'deepseek_api_key': deepSeekApiKey,
        if (mathpixAppId != null) 'mathpix_app_id': mathpixAppId,
        if (mathpixAppKey != null) 'mathpix_app_key': mathpixAppKey,
        if (mathpixBaseUrl != null) 'mathpix_base_url': mathpixBaseUrl,
      };

  factory StoredApiCredentials.fromJson(Map<String, dynamic> json) {
    String? s(String key) {
      final v = json[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return StoredApiCredentials(
      deepSeekApiKey: s('deepseek_api_key'),
      mathpixAppId: s('mathpix_app_id'),
      mathpixAppKey: s('mathpix_app_key'),
      mathpixBaseUrl: s('mathpix_base_url'),
    );
  }
}
