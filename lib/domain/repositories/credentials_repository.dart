/// Secure OS credential store for the user's DeepSeek API key.
///
/// Keys must never be written to SQLite, logs, or crash reports.
abstract interface class CredentialsRepository {
  Future<String?> getDeepSeekApiKey();

  Future<void> setDeepSeekApiKey(String apiKey);

  Future<void> deleteDeepSeekApiKey();

  Future<bool> hasDeepSeekApiKey();
}
