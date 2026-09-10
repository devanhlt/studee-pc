import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Secure OS credential store for API keys (DeepSeek, Mathpix).
///
/// Keys must never be written to SQLite, logs, or crash reports.
abstract interface class CredentialsRepository {
  /// One Keychain read for all app secrets (preferred).
  Future<StoredApiCredentials> loadAll();

  Future<String?> getDeepSeekApiKey();

  Future<void> setDeepSeekApiKey(String apiKey);

  Future<void> deleteDeepSeekApiKey();

  Future<bool> hasDeepSeekApiKey();

  Future<String?> getMathpixAppId();

  Future<String?> getMathpixAppKey();

  /// Optional OCR endpoint override (Mathpix or future middleware).
  Future<String?> getMathpixBaseUrl();

  Future<void> setMathpixAppId(String appId);

  Future<void> setMathpixAppKey(String appKey);

  Future<void> setMathpixBaseUrl(String? baseUrl);

  Future<void> deleteMathpixCredentials();

  Future<bool> hasMathpixCredentials();
}
