import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

/// A persisted question linked to a knowledge unit.
class Question extends Equatable {
  const Question({
    required this.id,
    required this.knowledgeUnitId,
    this.questionNumber,
    required this.questionType,
    required this.content,
    required this.normalizedContent,
    required this.questionFingerprint,
    this.answerLabel,
    this.answerContent,
    this.explanation,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.choices = const [],
    this.sourcePriority = 0,
    this.sourceTitle,
    this.page,
  });

  final String id;
  final String knowledgeUnitId;
  final String? questionNumber;
  final QuestionType questionType;
  final String content;
  final String normalizedContent;
  final String questionFingerprint;
  final String? answerLabel;
  final String? answerContent;
  final String? explanation;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuestionChoice> choices;
  final int sourcePriority;
  final String? sourceTitle;
  final int? page;

  Question copyWith({
    String? id,
    String? knowledgeUnitId,
    String? questionNumber,
    QuestionType? questionType,
    String? content,
    String? normalizedContent,
    String? questionFingerprint,
    String? answerLabel,
    String? answerContent,
    String? explanation,
    VerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<QuestionChoice>? choices,
    int? sourcePriority,
    String? sourceTitle,
    int? page,
  }) {
    return Question(
      id: id ?? this.id,
      knowledgeUnitId: knowledgeUnitId ?? this.knowledgeUnitId,
      questionNumber: questionNumber ?? this.questionNumber,
      questionType: questionType ?? this.questionType,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      questionFingerprint: questionFingerprint ?? this.questionFingerprint,
      answerLabel: answerLabel ?? this.answerLabel,
      answerContent: answerContent ?? this.answerContent,
      explanation: explanation ?? this.explanation,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      choices: choices ?? this.choices,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [
        id,
        knowledgeUnitId,
        questionNumber,
        questionType,
        content,
        normalizedContent,
        questionFingerprint,
        answerLabel,
        answerContent,
        explanation,
        verificationStatus,
        createdAt,
        updatedAt,
        choices,
        sourcePriority,
        sourceTitle,
        page,
      ];
}
