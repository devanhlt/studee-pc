import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Secure OS credential store for the Studee activation code (and legacy keys).
///
/// Secrets must never be written to SQLite, logs, or crash reports.
abstract interface class CredentialsRepository {
  /// One Keychain read for all app secrets (preferred).
  Future<StoredApiCredentials> loadAll();

  Future<String?> getActivationCode();

  Future<void> setActivationCode(String code);

  Future<void> deleteActivationCode();

  Future<bool> hasActivationCode();

  /// Returns the activation code (Bearer token for the middleware).
  Future<String?> getDeepSeekApiKey();

  Future<void> setDeepSeekApiKey(String apiKey);

  Future<void> deleteDeepSeekApiKey();

  Future<bool> hasDeepSeekApiKey();

  Future<String?> getMathpixAppId();

  Future<String?> getMathpixAppKey();

  /// Optional OCR endpoint override (defaults to Studee middleware).
  Future<String?> getMathpixBaseUrl();

  Future<void> setMathpixAppId(String appId);

  Future<void> setMathpixAppKey(String appKey);

  Future<void> setMathpixBaseUrl(String? baseUrl);

  Future<void> setMathpixCredentials({
    required String appId,
    required String appKey,
    String? baseUrl,
  });

  Future<void> deleteMathpixCredentials();

  Future<bool> hasMathpixCredentials();
}
