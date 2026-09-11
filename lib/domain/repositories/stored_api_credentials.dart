/// Snapshot of secrets loaded in one Keychain read.
///
/// Product auth is an [activationCode]. Legacy DeepSeek/Mathpix fields may still
/// exist from older installs but are unused by the middleware path.
class StoredApiCredentials {
  const StoredApiCredentials({
    this.activationCode,
    this.deepSeekApiKey,
    this.mathpixAppId,
    this.mathpixAppKey,
    this.mathpixBaseUrl,
  });

  final String? activationCode;
  final String? deepSeekApiKey;
  final String? mathpixAppId;
  final String? mathpixAppKey;
  final String? mathpixBaseUrl;

  bool get hasActivationCode =>
      activationCode != null && activationCode!.trim().isNotEmpty;

  /// Backward-compatible alias: cloud access requires an activation code.
  bool get hasDeepSeekApiKey => hasActivationCode;

  bool get hasMathpixCredentials => hasActivationCode;

  bool get hasAny =>
      hasActivationCode ||
      (deepSeekApiKey != null && deepSeekApiKey!.isNotEmpty) ||
      (mathpixAppId != null && mathpixAppId!.isNotEmpty) ||
      (mathpixAppKey != null && mathpixAppKey!.isNotEmpty) ||
      (mathpixBaseUrl != null && mathpixBaseUrl!.isNotEmpty);

  StoredApiCredentials copyWith({
    String? activationCode,
    String? deepSeekApiKey,
    String? mathpixAppId,
    String? mathpixAppKey,
    String? mathpixBaseUrl,
    bool clearActivationCode = false,
    bool clearDeepSeek = false,
    bool clearMathpixAppId = false,
    bool clearMathpixAppKey = false,
    bool clearMathpixBaseUrl = false,
    bool clearMathpix = false,
  }) {
    return StoredApiCredentials(
      activationCode: clearActivationCode
          ? null
          : (activationCode ?? this.activationCode),
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
        if (activationCode != null) 'activation_code': activationCode,
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
      activationCode: s('activation_code'),
      deepSeekApiKey: s('deepseek_api_key'),
      mathpixAppId: s('mathpix_app_id'),
      mathpixAppKey: s('mathpix_app_key'),
      mathpixBaseUrl: s('mathpix_base_url'),
    );
  }
}
