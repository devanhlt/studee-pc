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

  /// One-time price in VND for a code with [maxSolves] (matches marketing site).
  int get amountVnd => switch (this) {
        ActivationRequestPlan.basic => 19000,
        ActivationRequestPlan.pro => 49000,
        ActivationRequestPlan.triplePro => 88000,
      };

  /// Solve quota bundled with this code.
  int get maxSolves => switch (this) {
        ActivationRequestPlan.basic => 100,
        ActivationRequestPlan.pro => 500,
        ActivationRequestPlan.triplePro => 1500,
      };

  String get amountLabel => ActivationRequestConfig.formatVnd(amountVnd);

  String get solvesLabel =>
      '${ActivationRequestConfig.formatNumber(maxSolves)} lượt';

  /// Dropdown row: "Basic — 19.000₫ · 100 lượt"
  String get dropdownLabel => '$label — $amountLabel · $solvesLabel';
}

/// Bank-transfer request config for activation codes.
abstract final class ActivationRequestConfig {
  static const List<ActivationRequestPlan> plans = ActivationRequestPlan.values;

  /// Optional static merchant QR. When present it is preferred over the
  /// generated payload QR (drop a VietQR PNG at this path).
  static const String paymentQrAsset = 'assets/images/studee_payment_qr.png';

  /// Fallback QR payload when no asset is bundled.
  static String qrPayloadFor({
    required ActivationRequestPlan plan,
    required String transferCode,
  }) =>
      'STUDEE ${plan.label.toUpperCase()} ${plan.amountVnd}VND ND:$transferCode';

  static String formatNumber(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static String formatVnd(int amount) => '${formatNumber(amount)}₫';
}
