import 'package:studee_pc/data/backend/quota_tokens.dart';

/// Plans offered on the in-app "Yêu cầu mã" payment screen.
enum ActivationRequestPlan {
  basic,
  pro,
  triplePro,
}

extension ActivationRequestPlanX on ActivationRequestPlan {
  String get id => switch (this) {
        ActivationRequestPlan.basic => 'basic',
        ActivationRequestPlan.pro => 'pro',
        ActivationRequestPlan.triplePro => '3xpro',
      };

  String get label => switch (this) {
        ActivationRequestPlan.basic => 'Basic',
        ActivationRequestPlan.pro => 'Pro',
        ActivationRequestPlan.triplePro => '3xPro',
      };

  /// Display price in VND (server is source of truth at checkout).
  int get amountVnd => switch (this) {
        ActivationRequestPlan.basic => 19000,
        ActivationRequestPlan.pro => 49000,
        ActivationRequestPlan.triplePro => 88000,
      };

  /// Solve quota bundled with this code, in token (server enforces at issue).
  int get maxTokens => switch (this) {
        ActivationRequestPlan.basic => 100 * QuotaTokens.perLegacySolve,
        ActivationRequestPlan.pro => 500 * QuotaTokens.perLegacySolve,
        ActivationRequestPlan.triplePro => 1500 * QuotaTokens.perLegacySolve,
      };

  String get amountLabel => ActivationRequestConfig.formatVnd(amountVnd);

  String get tokensLabel =>
      '${ActivationRequestConfig.formatTokens(maxTokens)} token';

  int get validityDays => switch (this) {
        ActivationRequestPlan.basic => 30,
        ActivationRequestPlan.pro => 60,
        ActivationRequestPlan.triplePro => 90,
      };

  String get dropdownLabel => label;
}

/// Display helpers for activation purchase UI.
abstract final class ActivationRequestConfig {
  static const List<ActivationRequestPlan> plans = ActivationRequestPlan.values;

  static String formatNumber(int value, {String separator = '.'}) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(separator);
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static String formatTokens(int value) => formatNumber(value, separator: ',');

  static String formatVnd(int amount) => '${formatNumber(amount)}₫';

  static String formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }
}
