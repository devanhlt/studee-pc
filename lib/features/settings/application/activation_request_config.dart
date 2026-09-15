/// Display helpers for activation purchase UI.
abstract final class ActivationRequestConfig {
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

/// A sellable package from the Studee backend catalog.
class SellablePackage {
  const SellablePackage({
    required this.id,
    required this.label,
    required this.amountVnd,
    required this.maxTokens,
    required this.ttlDays,
    this.sortOrder = 0,
  });

  final String id;
  final String label;
  final int amountVnd;
  final int maxTokens;
  final int ttlDays;
  final int sortOrder;

  String get amountLabel => ActivationRequestConfig.formatVnd(amountVnd);

  String get tokensLabel =>
      '${ActivationRequestConfig.formatTokens(maxTokens)} token';

  int get validityDays => ttlDays;

  factory SellablePackage.fromJson(Map<String, dynamic> json) {
    return SellablePackage(
      id: '${json['id']}',
      label: '${json['label']}',
      amountVnd: (json['amount_vnd'] as num).toInt(),
      maxTokens: (json['max_tokens'] as num).toInt(),
      ttlDays: (json['ttl_days'] as num).toInt(),
      sortOrder: json['sort_order'] is num
          ? (json['sort_order'] as num).toInt()
          : 0,
    );
  }
}
