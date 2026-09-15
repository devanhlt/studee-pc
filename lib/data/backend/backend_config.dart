/// Studee middleware backend (activation + API proxy).
abstract final class BackendConfig {
  /// Production middleware host.
  static const String defaultBaseUrl = 'https://studied.vinius.org';

  /// Override with `--dart-define=STUDEE_BACKEND_URL=…` for local/dev.
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('STUDEE_BACKEND_URL');
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return defaultBaseUrl;
  }

  static const String entitlementPath = '/v1/entitlement';
  static const String chatCompletionsPath = '/v1/chat/completions';
  static const String consumeSolvePath = '/v1/solves/consume';
  static const String checkoutPath = '/v1/checkout';
  static const String packagesPath = '/v1/packages';
}
