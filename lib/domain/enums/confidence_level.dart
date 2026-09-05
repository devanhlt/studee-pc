/// Application-computed confidence — never trust model self-report.
enum ConfidenceLevel {
  high,
  medium,
  low,
  conflict;

  String get wireName => name;

  static ConfidenceLevel fromWire(String value) {
    return ConfidenceLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConfidenceLevel.low,
    );
  }

  String get labelVi => switch (this) {
        ConfidenceLevel.high => 'Cao',
        ConfidenceLevel.medium => 'Trung bình',
        ConfidenceLevel.low => 'Thấp',
        ConfidenceLevel.conflict => 'Mâu thuẫn',
      };
}
