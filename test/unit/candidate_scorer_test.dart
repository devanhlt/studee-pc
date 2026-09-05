import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/candidate_scorer.dart';

void main() {
  const scorer = CandidateScorer();

  group('CandidateScorer numeric identity', () {
    test('same matrix wording with different numbers is NOT high-lexical', () {
      const imported =
          'Cho 2 ma trận A = [[2,1,-1],[3,4,2],[5,-2,3]] và B = [[1,2,0],[4,5,3],[2,-3,1]]. Tính 2A + 3B = ?';
      const live =
          'Cho 2 ma trận A = [[1,0,2],[0,3,1],[4,1,0]] và B = [[2,1,0],[1,0,3],[0,2,1]]. Tính 2A + 3B = ?';

      final question = ParsedQuestion(
        questionType: QuestionType.multipleChoice,
        content: live,
        choices: const [
          ParsedChoice(label: 'A', content: '[[1,1,1],[1,1,1],[1,1,1]]'),
          ParsedChoice(label: 'B', content: '[[2,2,2],[2,2,2],[2,2,2]]'),
        ],
      );
      final candidate = RankedCandidate(
        localId: 'imp',
        questionId: 'imp',
        content: imported,
        verificationStatus: VerificationStatus.reviewed,
        score: 0,
        answerLabel: 'A',
        answerContent: '[[7,8,-2],[18,23,13],[16,-13,9]]',
        choices: const [],
      );

      final scored = scorer.score(question: question, candidate: candidate);
      expect(scored.highLexicalMatch, isFalse);
      expect(scored.exactFingerprintMatch, isFalse);
    });

    test('identical stem+numbers is high-lexical', () {
      const text =
          'Cho 2 ma trận A = [[2,1,-1],[3,4,2],[5,-2,3]] và B = [[1,2,0],[4,5,3],[2,-3,1]]. Tính 2A + 3B = ?';
      final question = ParsedQuestion(
        questionType: QuestionType.textResponse,
        content: text,
        choices: const [],
      );
      final candidate = RankedCandidate(
        localId: 'same',
        questionId: 'same',
        content: text,
        verificationStatus: VerificationStatus.reviewed,
        score: 0,
        answerContent: '[[7,8,-2],[18,23,13],[16,-13,9]]',
      );

      final scored = scorer.score(question: question, candidate: candidate);
      expect(scored.exactFingerprintMatch || scored.highLexicalMatch, isTrue);
    });
  });
}
