import 'package:equatable/equatable.dart';

/// A stored multiple-choice option for a [Question].
class QuestionChoice extends Equatable {
  const QuestionChoice({
    required this.id,
    required this.questionId,
    required this.label,
    required this.content,
    required this.normalizedContent,
    required this.sortOrder,
  });

  final String id;
  final String questionId;
  final String label;
  final String content;
  final String normalizedContent;
  final int sortOrder;

  QuestionChoice copyWith({
    String? id,
    String? questionId,
    String? label,
    String? content,
    String? normalizedContent,
    int? sortOrder,
  }) {
    return QuestionChoice(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      label: label ?? this.label,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        label,
        content,
        normalizedContent,
        sortOrder,
      ];
}
