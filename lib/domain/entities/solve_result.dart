import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/result_reference.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/domain/enums/question_type.dart';

/// Final solve output after precedence, model response, and validation.
class SolveResult extends Equatable {
  const SolveResult({
    required this.id,
    this.sessionId,
    required this.questionType,
    this.finalAnswerLabel,
    this.finalAnswerContent,
    this.shortAnswer,
    required this.explanationMarkdown,
    required this.confidence,
    required this.modelKnowledgeUsed,
    this.missingInformation = false,
    this.warnings = const [],
    this.usedEvidenceIds = const [],
    this.references = const [],
    this.promptVersion,
    required this.createdAt,
  });

  final String id;
  final String? sessionId;
  final QuestionType questionType;
  final String? finalAnswerLabel;
  final String? finalAnswerContent;
  final String? shortAnswer;
  final String explanationMarkdown;
  final ConfidenceLevel confidence;
  final bool modelKnowledgeUsed;
  final bool missingInformation;
  final List<String> warnings;
  final List<String> usedEvidenceIds;
  final List<ResultReference> references;
  final String? promptVersion;
  final DateTime createdAt;

  bool get fromImportedKnowledge => !modelKnowledgeUsed;

  @override
  List<Object?> get props => [
        id,
        sessionId,
        questionType,
        finalAnswerLabel,
        finalAnswerContent,
        shortAnswer,
        explanationMarkdown,
        confidence,
        modelKnowledgeUsed,
        missingInformation,
        warnings,
        usedEvidenceIds,
        references,
        promptVersion,
        createdAt,
      ];
}
