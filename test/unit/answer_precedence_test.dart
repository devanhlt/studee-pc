import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';

ParsedQuestion _mcQuestion({
  String answerContent = 'định thức khác không',
  String answerLabel = 'C',
}) {
  return ParsedQuestion(
    questionType: QuestionType.multipleChoice,
    content: 'Ma trận A khả nghịch khi nào?',
    choices: [
      const ParsedChoice(label: 'A', content: 'det(A) = 0'),
      const ParsedChoice(label: 'B', content: 'rank(A) < n'),
      ParsedChoice(label: answerLabel, content: answerContent),
      const ParsedChoice(label: 'D', content: 'A = 0'),
    ],
  );
}

RankedCandidate _candidate({
  required String id,
  required VerificationStatus status,
  String? answerLabel,
  String? answerContent,
  bool exact = false,
  bool highLexical = false,
  double score = 0.9,
}) {
  return RankedCandidate(
    localId: id,
    questionId: id,
    content: 'Ma trận A khả nghịch khi nào?',
    verificationStatus: status,
    score: score,
    answerLabel: answerLabel,
    answerContent: answerContent,
    exactFingerprintMatch: exact,
    highLexicalMatch: highLexical,
  );
}

void main() {
  const precedence = AnswerPrecedence();

  group('AnswerPrecedence', () {
    test('exact official → FixedOfficialDecision with fixed constraint', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'q1',
            status: VerificationStatus.official,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            exact: true,
          ),
        ],
      );

      expect(decision, isA<FixedOfficialDecision>());
      final fixed = decision as FixedOfficialDecision;
      expect(fixed.constraint.fixed, isTrue);
      expect(fixed.constraint.answerLabel, 'C');
      expect(fixed.constraint.answerContent, 'định thức khác không');
      expect(fixed.mapped.label, 'C');
    });

    test('reviewed high match → PreferStoredReviewedDecision', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'q2',
            status: VerificationStatus.reviewed,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            exact: true,
          ),
        ],
      );

      expect(decision, isA<PreferStoredReviewedDecision>());
      final reviewed = decision as PreferStoredReviewedDecision;
      expect(reviewed.constraint.fixed, isTrue);
      expect(reviewed.mapped.label, 'C');
    });

    test('same content with different A/B/C labels → PreferStored (not conflict)',
        () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'v1',
            status: VerificationStatus.reviewed,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            exact: true,
          ),
          _candidate(
            id: 'v2',
            status: VerificationStatus.reviewed,
            answerLabel: 'C',
            answerContent: 'A. định thức khác không',
            exact: true,
          ),
        ],
      );

      expect(decision, isNot(isA<TrustedConflictDecision>()));
      expect(decision.constraint.fixed, isTrue);
      expect(decision.constraint.answerContent, 'định thức khác không');
    });

    test('same strong stem with different answers → TrustedConflictDecision', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'v1',
            status: VerificationStatus.reviewed,
            answerLabel: 'A',
            answerContent: 'phương án A là sai',
            exact: true,
          ),
          _candidate(
            id: 'v2',
            status: VerificationStatus.reviewed,
            answerLabel: 'C',
            answerContent: 'định thức khác không',
            exact: true,
          ),
        ],
      );

      expect(decision, isA<TrustedConflictDecision>());
      expect(decision.constraint.fixed, isFalse);
      final conflict = decision as TrustedConflictDecision;
      expect(conflict.allCandidates, hasLength(2));
      expect(conflict.warning, contains('đáp án đã nhập khác nhau'));
    });

    test('unreviewed strong match → PreferStored', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'q4',
            status: VerificationStatus.unreviewed,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            highLexical: true,
          ),
        ],
      );

      expect(decision, isA<PreferStoredReviewedDecision>());
      expect(decision.constraint.fixed, isTrue);
      expect((decision as PreferStoredReviewedDecision).mapped.label, 'C');
    });

    test('unreviewed without answer → SoftMatchContextDecision', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'q4b',
            status: VerificationStatus.unreviewed,
          ),
        ],
      );

      expect(decision, isA<SoftMatchContextDecision>());
      expect(decision.constraint.fixed, isFalse);
    });

    test('reviewed soft/FTS match does NOT lock stored answer', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'soft',
            status: VerificationStatus.reviewed,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            highLexical: false,
            exact: false,
            score: 0.7,
          ),
        ],
      );

      expect(decision, isA<SoftMatchContextDecision>());
      expect(decision.constraint.fixed, isFalse);
      expect(decision.modelKnowledgeDisclosure, isFalse);
      expect(decision.warnings.first, contains('chưa đủ khớp'));
    });

    test('empty → ModelKnowledgeDecision with disclosure', () {
      final decision = precedence.resolve(
        currentQuestion: _mcQuestion(),
        candidates: const [],
      );

      expect(decision, isA<ModelKnowledgeDecision>());
      final model = decision as ModelKnowledgeDecision;
      expect(model.modelKnowledgeDisclosure, isTrue);
      expect(model.disclosure, isNotEmpty);
      expect(model.constraint.fixed, isFalse);
    });

    test('rejected candidates are not used', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'rej',
            status: VerificationStatus.rejected,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            exact: true,
          ),
        ],
      );

      expect(decision, isA<ModelKnowledgeDecision>());
    });

    test('rejected ignored while reviewed high match still wins', () {
      final question = _mcQuestion();
      final decision = precedence.resolve(
        currentQuestion: question,
        candidates: [
          _candidate(
            id: 'rej',
            status: VerificationStatus.rejected,
            answerLabel: 'A',
            answerContent: 'det(A) = 0',
            exact: true,
          ),
          _candidate(
            id: 'ok',
            status: VerificationStatus.reviewed,
            answerLabel: 'A',
            answerContent: 'định thức khác không',
            highLexical: true,
          ),
        ],
      );

      expect(decision, isA<PreferStoredReviewedDecision>());
      expect((decision as PreferStoredReviewedDecision).mapped.label, 'C');
    });
  });
}
