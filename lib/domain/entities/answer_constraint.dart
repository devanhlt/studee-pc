import 'package:equatable/equatable.dart';

/// Constraint telling the model whether the final answer is fixed by code.
class AnswerConstraint extends Equatable {
  const AnswerConstraint({
    required this.fixed,
    this.answerLabel,
    this.answerContent,
  });

  /// When true, application code has fixed the answer; the model may only explain.
  final bool fixed;
  final String? answerLabel;
  final String? answerContent;

  static const AnswerConstraint none = AnswerConstraint(fixed: false);

  @override
  List<Object?> get props => [fixed, answerLabel, answerContent];
}
