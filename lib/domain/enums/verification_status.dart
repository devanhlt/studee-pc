/// Verification state for knowledge units and questions.
enum VerificationStatus {
  official,
  reviewed,
  unreviewed,
  inferred,
  conflicted,
  rejected;

  /// Official and reviewed answers may be used as fixed final answers.
  bool get isTrusted =>
      this == VerificationStatus.official ||
      this == VerificationStatus.reviewed;

  /// Never retrieve rejected content.
  bool get isRetrievable => this != VerificationStatus.rejected;

  String get wireName => name;

  static VerificationStatus fromWire(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.unreviewed,
    );
  }

  String get labelVi => switch (this) {
        VerificationStatus.official => 'Chính thức',
        VerificationStatus.reviewed => 'Đã duyệt',
        VerificationStatus.unreviewed => 'Chưa duyệt',
        VerificationStatus.inferred => 'Suy luận Trợ lý Stud',
        VerificationStatus.conflicted => 'Mâu thuẫn',
        VerificationStatus.rejected => 'Từ chối',
      };
}
