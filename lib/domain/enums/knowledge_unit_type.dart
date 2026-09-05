/// Types of structured knowledge extracted from sources.
enum KnowledgeUnitType {
  theory,
  definition,
  formula,
  theorem,
  example,
  question,
  answerKey,
  solution,
  table,
  note;

  String get wireName => switch (this) {
        KnowledgeUnitType.answerKey => 'answer_key',
        _ => name,
      };

  static KnowledgeUnitType fromWire(String value) {
    return switch (value) {
      'answer_key' => KnowledgeUnitType.answerKey,
      'theory' => KnowledgeUnitType.theory,
      'definition' => KnowledgeUnitType.definition,
      'formula' => KnowledgeUnitType.formula,
      'theorem' => KnowledgeUnitType.theorem,
      'example' => KnowledgeUnitType.example,
      'question' => KnowledgeUnitType.question,
      'solution' => KnowledgeUnitType.solution,
      'table' => KnowledgeUnitType.table,
      'note' => KnowledgeUnitType.note,
      _ => KnowledgeUnitType.note,
    };
  }

  String get labelVi => switch (this) {
        KnowledgeUnitType.theory => 'Lý thuyết',
        KnowledgeUnitType.definition => 'Định nghĩa',
        KnowledgeUnitType.formula => 'Công thức',
        KnowledgeUnitType.theorem => 'Định lý',
        KnowledgeUnitType.example => 'Ví dụ',
        KnowledgeUnitType.question => 'Câu hỏi',
        KnowledgeUnitType.answerKey => 'Đáp án',
        KnowledgeUnitType.solution => 'Lời giải',
        KnowledgeUnitType.table => 'Bảng',
        KnowledgeUnitType.note => 'Ghi chú',
      };
}
