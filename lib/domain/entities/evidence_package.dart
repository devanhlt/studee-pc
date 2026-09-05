import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/evidence_item.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';

/// Token-limited evidence package for grounded answer generation.
class EvidencePackage extends Equatable {
  const EvidencePackage({
    required this.currentQuestion,
    required this.answerConstraint,
    required this.evidence,
    this.warnings = const [],
    this.estimatedTokens = 0,
  });

  final ParsedQuestion currentQuestion;
  final AnswerConstraint answerConstraint;
  final List<EvidenceItem> evidence;
  final List<String> warnings;
  final int estimatedTokens;

  @override
  List<Object?> get props => [
        currentQuestion,
        answerConstraint,
        evidence,
        warnings,
        estimatedTokens,
      ];
}
