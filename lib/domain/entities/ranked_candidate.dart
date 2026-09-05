import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

/// A scored retrieval candidate (question or knowledge unit).
class RankedCandidate extends Equatable {
  const RankedCandidate({
    required this.localId,
    required this.content,
    required this.verificationStatus,
    required this.score,
    this.questionId,
    this.unitType,
    this.questionType,
    this.answerLabel,
    this.answerContent,
    this.explanation,
    this.choices = const [],
    this.sourcePriority = 0,
    this.exactFingerprintMatch = false,
    this.highLexicalMatch = false,
    this.sourceTitle,
    this.page,
    this.normalizedContent,
    this.choiceSetFingerprint,
  });

  final String localId;
  final String? questionId;
  final KnowledgeUnitType? unitType;
  final QuestionType? questionType;
  final String content;
  final String? normalizedContent;
  final String? answerLabel;
  final String? answerContent;
  final String? explanation;
  final List<QuestionChoice> choices;
  final VerificationStatus verificationStatus;
  final int sourcePriority;
  final double score;
  final bool exactFingerprintMatch;
  final bool highLexicalMatch;
  final String? sourceTitle;
  final int? page;
  final String? choiceSetFingerprint;

  bool get hasAnswer =>
      (answerContent != null && answerContent!.trim().isNotEmpty) ||
      (answerLabel != null && answerLabel!.trim().isNotEmpty);

  RankedCandidate copyWith({
    String? localId,
    String? questionId,
    KnowledgeUnitType? unitType,
    QuestionType? questionType,
    String? content,
    String? normalizedContent,
    String? answerLabel,
    String? answerContent,
    String? explanation,
    List<QuestionChoice>? choices,
    VerificationStatus? verificationStatus,
    int? sourcePriority,
    double? score,
    bool? exactFingerprintMatch,
    bool? highLexicalMatch,
    String? sourceTitle,
    int? page,
    String? choiceSetFingerprint,
  }) {
    return RankedCandidate(
      localId: localId ?? this.localId,
      questionId: questionId ?? this.questionId,
      unitType: unitType ?? this.unitType,
      questionType: questionType ?? this.questionType,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      answerLabel: answerLabel ?? this.answerLabel,
      answerContent: answerContent ?? this.answerContent,
      explanation: explanation ?? this.explanation,
      choices: choices ?? this.choices,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      score: score ?? this.score,
      exactFingerprintMatch:
          exactFingerprintMatch ?? this.exactFingerprintMatch,
      highLexicalMatch: highLexicalMatch ?? this.highLexicalMatch,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      page: page ?? this.page,
      choiceSetFingerprint: choiceSetFingerprint ?? this.choiceSetFingerprint,
    );
  }

  @override
  List<Object?> get props => [
        localId,
        questionId,
        unitType,
        questionType,
        content,
        normalizedContent,
        answerLabel,
        answerContent,
        explanation,
        choices,
        verificationStatus,
        sourcePriority,
        score,
        exactFingerprintMatch,
        highLexicalMatch,
        sourceTitle,
        page,
        choiceSetFingerprint,
      ];
}
