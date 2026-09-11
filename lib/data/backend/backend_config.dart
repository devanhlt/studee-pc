/// Studee middleware backend (activation + API proxy).
abstract final class BackendConfig {
  /// Production middleware host.
  /// Prefer custom domain when DNS is live; Vercel alias is the stable default.
  static const String defaultBaseUrl = 'https://studee-api.vercel.app';

  /// Override with `--dart-define=STUDEE_BACKEND_URL=…` for local/dev.
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('STUDEE_BACKEND_URL');
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return defaultBaseUrl;
  }

  static const String entitlementPath = '/v1/entitlement';
  static const String chatCompletionsPath = '/v1/chat/completions';
  static const String consumeSolvePath = '/v1/solves/consume';
}
