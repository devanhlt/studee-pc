import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';
import 'package:studee_pc/domain/services/confidence_calculator.dart';

RankedCandidate _c({
  required String id,
  required VerificationStatus status,
  bool exact = false,
  bool highLexical = false,
  double score = 0.9,
  KnowledgeUnitType? unitType,
  String? answerContent = 'đáp án',
}) {
  return RankedCandidate(
    localId: id,
    content: 'nội dung',
    verificationStatus: status,
    score: score,
    exactFingerprintMatch: exact,
    highLexicalMatch: highLexical,
    answerContent: answerContent,
    unitType: unitType,
  );
}

void main() {
  const calc = ConfidenceCalculator();

  group('ConfidenceCalculator.calculate', () {
    test('maps FixedOfficialDecision → High', () {
      final level = calc.calculate(
        decision: FixedOfficialDecision(
          candidate: _c(id: '1', status: VerificationStatus.official, exact: true),
          mapped: const MappedAnswer(
            label: 'A',
            content: 'một',
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(
            fixed: true,
            answerLabel: 'A',
            answerContent: 'một',
          ),
        ),
        evidenceCandidates: const [],
      );
      expect(level, ConfidenceLevel.high);
    });

    test('maps PreferStoredReviewedDecision with high match → High', () {
      final candidate =
          _c(id: '2', status: VerificationStatus.reviewed, exact: true);
      final level = calc.calculate(
        decision: PreferStoredReviewedDecision(
          candidate: candidate,
          mapped: const MappedAnswer(
            label: 'A',
            content: 'một',
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(fixed: true, answerLabel: 'A'),
        ),
        evidenceCandidates: [candidate],
      );
      expect(level, ConfidenceLevel.high);
    });

    test('maps PreferStoredReviewedDecision without high match → Medium', () {
      final candidate = _c(id: '2b', status: VerificationStatus.reviewed);
      final level = calc.calculate(
        decision: PreferStoredReviewedDecision(
          candidate: candidate,
          mapped: const MappedAnswer(
            label: 'A',
            content: 'một',
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(fixed: true, answerLabel: 'A'),
        ),
        evidenceCandidates: [candidate],
      );
      expect(level, ConfidenceLevel.medium);
    });

    test('maps TrustedConflictDecision → Conflict', () {
      final level = calc.calculate(
        decision: const TrustedConflictDecision(
          conflicting: [],
          warning: 'mâu thuẫn',
        ),
        evidenceCandidates: const [],
      );
      expect(level, ConfidenceLevel.conflict);
    });

    test('maps UnreviewedContextDecision → Low', () {
      final level = calc.calculate(
        decision: const UnreviewedContextDecision(
          contextCandidates: [],
          warning: 'chưa duyệt',
        ),
        evidenceCandidates: const [],
      );
      expect(level, ConfidenceLevel.low);
    });

    test('maps ModelKnowledgeDecision → Low', () {
      final level = calc.calculate(
        decision: const ModelKnowledgeDecision(disclosure: 'không có bằng chứng'),
        evidenceCandidates: const [],
      );
      expect(level, ConfidenceLevel.low);
    });

    test('CommonTrustedDecision high vs medium', () {
      final high = calc.calculate(
        decision: CommonTrustedDecision(
          candidates: [
            _c(id: 'a', status: VerificationStatus.reviewed, highLexical: true),
          ],
          mapped: const MappedAnswer(
            label: 'A',
            content: 'một',
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(fixed: true),
        ),
        evidenceCandidates: const [],
      );
      expect(high, ConfidenceLevel.high);

      final medium = calc.calculate(
        decision: CommonTrustedDecision(
          candidates: [
            _c(id: 'b', status: VerificationStatus.reviewed),
          ],
          mapped: const MappedAnswer(
            label: 'A',
            content: 'một',
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(fixed: true),
        ),
        evidenceCandidates: const [],
      );
      expect(medium, ConfidenceLevel.medium);
    });
  });

  group('ConfidenceCalculator.fromEvidence', () {
    test('trusted conflict → Conflict', () {
      expect(
        calc.fromEvidence(
          candidates: const [],
          trustedConflict: true,
          modelKnowledgeUsed: false,
        ),
        ConfidenceLevel.conflict,
      );
    });

    test('trusted exact/high → High', () {
      expect(
        calc.fromEvidence(
          candidates: [
            _c(id: '1', status: VerificationStatus.official, exact: true),
          ],
          trustedConflict: false,
          modelKnowledgeUsed: false,
        ),
        ConfidenceLevel.high,
      );
    });

    test('two trusted without high match → Medium', () {
      expect(
        calc.fromEvidence(
          candidates: [
            _c(id: '1', status: VerificationStatus.official),
            _c(id: '2', status: VerificationStatus.reviewed),
          ],
          trustedConflict: false,
          modelKnowledgeUsed: false,
        ),
        ConfidenceLevel.medium,
      );
    });

    test('model knowledge / empty → Low', () {
      expect(
        calc.fromEvidence(
          candidates: const [],
          trustedConflict: false,
          modelKnowledgeUsed: true,
        ),
        ConfidenceLevel.low,
      );
    });

    test('strong trusted theory → Medium', () {
      expect(
        calc.fromEvidence(
          candidates: [
            _c(
              id: 't',
              status: VerificationStatus.reviewed,
              score: 0.7,
              unitType: KnowledgeUnitType.formula,
              answerContent: null,
            ),
          ],
          trustedConflict: false,
          modelKnowledgeUsed: false,
        ),
        ConfidenceLevel.medium,
      );
    });
  });
}
