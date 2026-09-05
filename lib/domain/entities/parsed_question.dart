import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/enums/question_type.dart';

/// Question currently being solved (from OCR, paste, or image).
class ParsedQuestion extends Equatable {
  const ParsedQuestion({
    required this.questionType,
    required this.content,
    this.choices = const [],
    this.missingInformation = false,
    this.warnings = const [],
  });

  final QuestionType questionType;
  final String content;
  final List<ParsedChoice> choices;
  final bool missingInformation;
  final List<String> warnings;

  Iterable<String> get choiceContents => choices.map((c) => c.content);

  ParsedQuestion copyWith({
    QuestionType? questionType,
    String? content,
    List<ParsedChoice>? choices,
    bool? missingInformation,
    List<String>? warnings,
  }) {
    return ParsedQuestion(
      questionType: questionType ?? this.questionType,
      content: content ?? this.content,
      choices: choices ?? this.choices,
      missingInformation: missingInformation ?? this.missingInformation,
      warnings: warnings ?? this.warnings,
    );
  }

  @override
  List<Object?> get props => [
        questionType,
        content,
        choices,
        missingInformation,
        warnings,
      ];
}
