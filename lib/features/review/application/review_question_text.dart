import 'package:studee_pc/domain/entities/question.dart';

/// Builds the prompt text for one saved question (stem + choices, no answer).
String formatReviewQuestion(Question question, {int? number}) {
  final buf = StringBuffer();
  final storedNumber = question.questionNumber?.trim();
  if (storedNumber != null && storedNumber.isNotEmpty) {
    buf.writeln('Câu $storedNumber');
  } else if (number != null) {
    buf.writeln('Câu $number');
  }
  buf.writeln(question.content.trim());
  if (question.choices.isNotEmpty) {
    buf.writeln();
    for (final choice in question.choices) {
      final label = choice.label.trim();
      final content = choice.content.trim();
      if (label.isEmpty && content.isEmpty) continue;
      if (content.isEmpty) {
        buf.writeln(label);
      } else if (label.isEmpty) {
        buf.writeln(content);
      } else {
        buf.writeln('$label. $content');
      }
    }
  }
  return buf.toString().trim();
}
