import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';

/// Page or document text ready for structured extraction.
class StructureSourceRequest extends Equatable {
  const StructureSourceRequest({
    required this.sourceId,
    required this.pageTexts,
    this.promptVersion,
    this.language = 'vi',
  });

  final String sourceId;
  final List<StructurePageText> pageTexts;
  final String? promptVersion;
  final String language;

  @override
  List<Object?> get props => [sourceId, pageTexts, promptVersion, language];
}

class StructurePageText extends Equatable {
  const StructurePageText({
    required this.pageNumber,
    required this.text,
  });

  final int pageNumber;
  final String text;

  @override
  List<Object?> get props => [pageNumber, text];
}

/// Structured extraction result (units/questions as raw validated JSON maps).
class StructureSourceResponse extends Equatable {
  const StructureSourceResponse({
    required this.knowledgeUnits,
    required this.questions,
    this.relations = const [],
    this.promptVersion,
    this.rawJson,
  });

  final List<Map<String, dynamic>> knowledgeUnits;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> relations;
  final String? promptVersion;
  final String? rawJson;

  @override
  List<Object?> get props =>
      [knowledgeUnits, questions, relations, promptVersion, rawJson];
}

class ParseQuestionRequest extends Equatable {
  const ParseQuestionRequest({
    required this.rawText,
    this.promptVersion,
    this.language = 'vi',
  });

  final String rawText;
  final String? promptVersion;
  final String language;

  @override
  List<Object?> get props => [rawText, promptVersion, language];
}

class GenerateAnswerRequest extends Equatable {
  const GenerateAnswerRequest({
    required this.evidencePackage,
    this.promptVersion,
    this.language = 'vi',
  });

  final EvidencePackage evidencePackage;
  final String? promptVersion;
  final String language;

  @override
  List<Object?> get props => [evidencePackage, promptVersion, language];
}

class RepairResponseRequest extends Equatable {
  const RepairResponseRequest({
    required this.evidencePackage,
    required this.invalidResponse,
    required this.validationErrors,
    this.promptVersion,
    this.language = 'vi',
  });

  final EvidencePackage evidencePackage;

  /// Invalid model output (may be truncated JSON). Never log verbatim in prod.
  final String invalidResponse;
  final List<String> validationErrors;
  final String? promptVersion;
  final String language;

  @override
  List<Object?> get props => [
        evidencePackage,
        invalidResponse,
        validationErrors,
        promptVersion,
        language,
      ];
}

/// DeepSeek API client boundary — no study content in [testConnection].
abstract interface class DeepSeekClient {
  /// Convert reviewed source text into structured knowledge/questions.
  Future<StructureSourceResponse> structureSource(StructureSourceRequest request);

  /// Parse the current question and choices from OCR/pasted text.
  Future<ParsedQuestion> parseQuestion(ParseQuestionRequest request);

  /// Generate a grounded answer from an evidence package.
  Future<DeepSeekAnswerResponse> generateAnswer(GenerateAnswerRequest request);

  /// One-shot repair for malformed structured output.
  Future<DeepSeekAnswerResponse> repairResponse(RepairResponseRequest request);

  /// Connectivity/auth check that must not send any study content.
  Future<void> testConnection();

  /// Short mnemonic tips for study-notes export (answer meaning, never A/B/C).
  /// Returns a map of [StudyTipItem.id] → tip text.
  Future<Map<String, String>> generateMemorizationTips(
    List<StudyTipItem> items,
  );

  /// Compact subject knowledge summary grounded only in provided Q&A + units.
  /// Returns Markdown body (no document title).
  Future<String> generateKnowledgeSummary({
    required String subjectName,
    required List<KnowledgeSummaryUnit> units,
    required List<KnowledgeSummaryQa> questions,
  });

  /// Canonical semantic keys for question meaning (no answers in keys).
  Future<Map<String, SemanticCanonicalization>> canonicalizeQuestions(
    List<CanonicalizeItem> items,
  );

  /// Pick whether a live question shares meaning with any stored candidate.
  Future<MeaningMatchResult> matchQuestionMeaning({
    required String liveQuestion,
    required List<MeaningMatchCandidate> candidates,
  });

  /// Start a cancellable API session (cancels any previous one).
  void beginCancellableSession();

  /// Abort the active cancellable session (in-flight waits / retries).
  void cancelActiveSession();
}

/// One question used when asking DeepSeek for a memorization tip.
class StudyTipItem extends Equatable {
  const StudyTipItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  @override
  List<Object?> get props => [id, question, answer];
}

/// General knowledge unit snippet for [DeepSeekClient.generateKnowledgeSummary].
class KnowledgeSummaryUnit extends Equatable {
  const KnowledgeSummaryUnit({
    required this.type,
    required this.content,
  });

  final String type;
  final String content;

  @override
  List<Object?> get props => [type, content];
}

/// Q&A pair for knowledge summary (answer as meaning, not A/B/C).
class KnowledgeSummaryQa extends Equatable {
  const KnowledgeSummaryQa({
    required this.question,
    this.answer,
    this.explanation,
  });

  final String question;
  final String? answer;
  final String? explanation;

  @override
  List<Object?> get props => [question, answer, explanation];
}

/// Input for [DeepSeekClient.canonicalizeQuestions].
class CanonicalizeItem extends Equatable {
  const CanonicalizeItem({
    required this.id,
    required this.questionText,
    this.choiceContents = const [],
  });

  final String id;
  final String questionText;
  final List<String> choiceContents;

  @override
  List<Object?> get props => [id, questionText, choiceContents];
}

/// Canonical meaning key plus optional FTS aliases.
class SemanticCanonicalization extends Equatable {
  const SemanticCanonicalization({
    required this.semanticKey,
    this.aliases = const [],
  });

  final String semanticKey;
  final List<String> aliases;

  @override
  List<Object?> get props => [semanticKey, aliases];
}

/// Candidate stored question for meaning match.
class MeaningMatchCandidate extends Equatable {
  const MeaningMatchCandidate({
    required this.id,
    required this.questionText,
  });

  final String id;
  final String questionText;

  @override
  List<Object?> get props => [id, questionText];
}

/// Result of [DeepSeekClient.matchQuestionMeaning].
class MeaningMatchResult extends Equatable {
  const MeaningMatchResult({
    this.id,
    required this.sameMeaning,
  });

  final String? id;
  final bool sameMeaning;

  @override
  List<Object?> get props => [id, sameMeaning];
}
