/// Supported question formats for solve and import.
enum QuestionType {
  multipleChoice,
  textResponse;

  String get wireName => switch (this) {
        QuestionType.multipleChoice => 'multiple_choice',
        QuestionType.textResponse => 'text_response',
      };

  static QuestionType fromWire(String value) {
    return switch (value) {
      'multiple_choice' => QuestionType.multipleChoice,
      'text_response' => QuestionType.textResponse,
      _ => QuestionType.textResponse,
    };
  }

  String get labelVi => switch (this) {
        QuestionType.multipleChoice => 'Trắc nghiệm',
        QuestionType.textResponse => 'Tự luận',
      };
}
