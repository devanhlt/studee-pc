/// Origin of an imported study source.
enum SourceType {
  image,
  screenshot,
  pastedText,
  pdf;

  String get wireName => switch (this) {
        SourceType.pastedText => 'pasted_text',
        _ => name,
      };

  static SourceType fromWire(String value) {
    return switch (value) {
      'image' => SourceType.image,
      'screenshot' => SourceType.screenshot,
      'pasted_text' => SourceType.pastedText,
      'pdf' => SourceType.pdf,
      _ => SourceType.image,
    };
  }

  String get labelVi => switch (this) {
        SourceType.image => 'Ảnh',
        SourceType.screenshot => 'Ảnh chụp màn hình',
        SourceType.pastedText => 'Văn bản dán',
        SourceType.pdf => 'PDF',
      };
}
