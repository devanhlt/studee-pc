import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/enums/question_type.dart';

/// Validated structured answer payload from DeepSeek.
class DeepSeekAnswerResponse extends Equatable {
  const DeepSeekAnswerResponse({
    required this.questionType,
    this.finalAnswerLabel,
    this.finalAnswerContent,
    this.shortAnswer,
    required this.explanationMarkdown,
    this.usedEvidenceIds = const [],
    this.modelKnowledgeUsed = false,
    this.missingInformation = false,
    this.warnings = const [],
    this.rawJson,
  });

  final QuestionType questionType;
  final String? finalAnswerLabel;
  final String? finalAnswerContent;
  final String? shortAnswer;
  final String explanationMarkdown;
  final List<String> usedEvidenceIds;
  final bool modelKnowledgeUsed;
  final bool missingInformation;
  final List<String> warnings;

  /// Optional raw payload for diagnostics when the user enables it.
  final String? rawJson;

  factory DeepSeekAnswerResponse.fromJson(Map<String, dynamic> json) {
    return DeepSeekAnswerResponse(
      questionType: QuestionType.fromWire(
        json['question_type'] as String? ?? 'text_response',
      ),
      finalAnswerLabel: json['final_answer_label'] as String?,
      finalAnswerContent: json['final_answer_content'] as String?,
      shortAnswer: json['short_answer'] as String?,
      explanationMarkdown: json['explanation_markdown'] as String? ?? '',
      usedEvidenceIds: (json['used_evidence_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      modelKnowledgeUsed: json['model_knowledge_used'] as bool? ?? false,
      missingInformation: json['missing_information'] as bool? ?? false,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'question_type': questionType.wireName,
        'final_answer_label': finalAnswerLabel,
        'final_answer_content': finalAnswerContent,
        'short_answer': shortAnswer,
        'explanation_markdown': explanationMarkdown,
        'used_evidence_ids': usedEvidenceIds,
        'model_knowledge_used': modelKnowledgeUsed,
        'missing_information': missingInformation,
        'warnings': warnings,
      };

  @override
  List<Object?> get props => [
        questionType,
        finalAnswerLabel,
        finalAnswerContent,
        shortAnswer,
        explanationMarkdown,
        usedEvidenceIds,
        modelKnowledgeUsed,
        missingInformation,
        warnings,
        rawJson,
      ];
}
