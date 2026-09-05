import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';
import 'package:studee_pc/domain/services/evidence_builder.dart';

RankedCandidate _ev({
  required String id,
  required VerificationStatus status,
  required String content,
  double score = 0.8,
}) {
  return RankedCandidate(
    localId: id,
    questionId: id,
    content: content,
    verificationStatus: status,
    score: score,
    answerContent: 'đáp án mẫu',
  );
}

void main() {
  const builder = EvidenceBuilder();

  final question = ParsedQuestion(
    questionType: QuestionType.multipleChoice,
    content: 'Câu hỏi ngắn?',
    choices: const [
      ParsedChoice(label: 'A', content: 'một'),
      ParsedChoice(label: 'B', content: 'hai'),
    ],
  );

  group('EvidenceBuilder', () {
    test('limits evidence units to max 8 (and typically ≥3 when available)', () {
      final candidates = List.generate(
        12,
        (i) => _ev(
          id: 'c$i',
          status: i < 4
              ? VerificationStatus.reviewed
              : VerificationStatus.unreviewed,
          content: 'Đơn vị kiến thức số $i với nội dung đủ dài.',
          score: 1.0 - i * 0.01,
        ),
      );

      final package = builder.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: const ModelKnowledgeDecision(disclosure: 'test'),
      );

      expect(package.evidence.length, lessThanOrEqualTo(8));
      expect(package.evidence.length, greaterThanOrEqualTo(3));
      expect(package.evidence.length, 8);
      expect(package.evidence.first.evidenceId, 'ev_001');
      expect(package.evidence.last.evidenceId, 'ev_008');
    });

    test('respects token budget', () {
      final tiny = EvidenceBuilder(
        minUnits: 3,
        maxUnits: 8,
        maxTokens: 80,
      );

      // Very long contents — after minUnits, further items should stop.
      final long = 'x' * 400;
      final candidates = List.generate(
        8,
        (i) => _ev(
          id: 't$i',
          status: VerificationStatus.reviewed,
          content: long,
        ),
      );

      final package = tiny.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: const ModelKnowledgeDecision(disclosure: 'test'),
      );

      expect(package.evidence.length, lessThanOrEqualTo(8));
      // With a tight budget, should not take all 8 long units.
      expect(package.evidence.length, lessThan(8));
      expect(
        package.estimatedTokens > 80 || package.warnings.isNotEmpty,
        isTrue,
      );
    });

    test('prefers trusted evidence when ranked first', () {
      final candidates = [
        _ev(
          id: 'trusted1',
          status: VerificationStatus.official,
          content: 'Lý thuyết chính thức về định thức.',
          score: 1.0,
        ),
        _ev(
          id: 'trusted2',
          status: VerificationStatus.reviewed,
          content: 'Câu hỏi đã duyệt liên quan.',
          score: 0.95,
        ),
        _ev(
          id: 'unrev1',
          status: VerificationStatus.unreviewed,
          content: 'Ghi chú chưa duyệt.',
          score: 0.5,
        ),
        _ev(
          id: 'unrev2',
          status: VerificationStatus.inferred,
          content: 'Suy luận AI.',
          score: 0.4,
        ),
        _ev(
          id: 'unrev3',
          status: VerificationStatus.unreviewed,
          content: 'Thêm ngữ cảnh chưa duyệt.',
          score: 0.35,
        ),
      ];

      final package = builder.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: const UnreviewedContextDecision(
          contextCandidates: [],
          warning: 'cảnh báo',
        ),
      );

      expect(package.evidence.length, greaterThanOrEqualTo(3));
      expect(package.evidence.take(2).map((e) => e.localId).toList(), [
        'trusted1',
        'trusted2',
      ]);
      expect(
        package.evidence.take(2).every((e) => e.verificationStatus.isTrusted),
        isTrue,
      );
    });
    test('includes stored answer in evidence content for questions', () {
      final candidates = [
        RankedCandidate(
          localId: 'q1',
          questionId: 'q1',
          content: 'Tìm nghiệm của hệ?',
          verificationStatus: VerificationStatus.reviewed,
          score: 1.0,
          answerLabel: 'A',
          answerContent: 'x1=3; x2=-3',
          explanation: 'Thế vào phương trình.',
          choices: const [],
        ),
      ];

      final package = builder.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: PreferStoredReviewedDecision(
          candidate: candidates.first,
          mapped: const MappedAnswer(
            label: 'A',
            content: 'x1=3; x2=-3',
            matchedByContent: false,
          ),
          constraint: const AnswerConstraint(
            fixed: true,
            answerLabel: 'A',
            answerContent: 'x1=3; x2=-3',
          ),
        ),
      );

      expect(package.evidence, hasLength(1));
      expect(package.evidence.first.content, contains('Cặp câu hỏi & đáp án'));
      expect(package.evidence.first.content, contains('Đáp án đi kèm'));
      expect(package.evidence.first.content, contains('x1=3; x2=-3'));
      expect(package.evidence.first.content, contains('Giải thích đi kèm'));
    });

    test('dedupes same stem+answer that only differ by A/B label', () {
      const stem = 'Pháp luật được phân loại dựa trên căn cứ nào?';
      const answer = 'Căn cứ vào đối tượng điều chỉnh và phương pháp điều chỉnh';
      final candidates = [
        RankedCandidate(
          localId: 'q-a',
          questionId: 'q-a',
          content: stem,
          verificationStatus: VerificationStatus.reviewed,
          score: 1.0,
          answerLabel: 'B',
          answerContent: answer,
          exactFingerprintMatch: true,
        ),
        RankedCandidate(
          localId: 'q-b',
          questionId: 'q-b',
          content: stem,
          verificationStatus: VerificationStatus.reviewed,
          score: 0.95,
          answerLabel: 'A',
          answerContent: 'A. $answer',
          exactFingerprintMatch: true,
        ),
        RankedCandidate(
          localId: 'other',
          questionId: 'other',
          content: 'Câu hỏi khác hoàn toàn?',
          verificationStatus: VerificationStatus.reviewed,
          score: 0.5,
          answerLabel: 'A',
          answerContent: 'khác hẳn',
        ),
      ];

      final package = builder.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: PreferStoredReviewedDecision(
          candidate: candidates.first,
          mapped: const MappedAnswer(
            label: 'A',
            content: answer,
            matchedByContent: true,
          ),
          constraint: const AnswerConstraint(
            fixed: true,
            answerLabel: 'A',
            answerContent: answer,
          ),
        ),
      );

      final ids = package.evidence.map((e) => e.localId).toList();
      expect(ids, contains('q-a'));
      expect(ids, isNot(contains('q-b')));
      expect(ids, contains('other'));
      expect(
        package.evidence.first.content,
        contains('không phụ thuộc chữ cái'),
      );
    });

    test('pure knowledge evidence is content-only without answer fields', () {
      final candidates = [
        RankedCandidate(
          localId: 'k1',
          content: 'Định thức bằng tích các trị riêng.',
          verificationStatus: VerificationStatus.reviewed,
          score: 0.9,
          unitType: KnowledgeUnitType.definition,
        ),
      ];

      final package = builder.build(
        currentQuestion: question,
        rankedCandidates: candidates,
        decision: SoftMatchContextDecision(
          contextCandidates: candidates,
          warning: 'ngữ cảnh',
        ),
      );

      expect(package.evidence, hasLength(1));
      expect(package.evidence.first.content, contains('Kiến thức'));
      expect(package.evidence.first.content, isNot(contains('Đáp án đi kèm')));
      expect(package.evidence.first.content, contains('Định thức bằng tích'));
    });
  });
}
