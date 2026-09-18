import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/features/subjects/application/subject_progress_report.dart';

Question _q({
  required String id,
  int practiceCount = 0,
  int incorrectCount = 0,
  String content = 'Câu hỏi',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Question(
    id: id,
    knowledgeUnitId: 'ku',
    questionType: QuestionType.multipleChoice,
    content: content,
    normalizedContent: content,
    questionFingerprint: id,
    verificationStatus: VerificationStatus.reviewed,
    createdAt: now,
    updatedAt: now,
    practiceCount: practiceCount,
    incorrectCount: incorrectCount,
  );
}

void main() {
  group('computeSubjectProgressStats', () {
    test('empty bank', () {
      final stats = computeSubjectProgressStats(const []);
      expect(stats.totalQuestions, 0);
      expect(stats.practicedQuestions, 0);
      expect(stats.averageScore, isNull);
      expect(stats.practicedLabel, '0/0');
      expect(stats.averageScoreLabel, '—');
    });

    test('practiced ratio and average score on 10-point scale', () {
      final stats = computeSubjectProgressStats([
        _q(id: 'a', practiceCount: 4, incorrectCount: 1),
        _q(id: 'b', practiceCount: 2, incorrectCount: 2),
        _q(id: 'c'),
      ]);
      expect(stats.totalQuestions, 3);
      expect(stats.practicedQuestions, 2);
      expect(stats.neverPracticedQuestions, 1);
      expect(stats.weakQuestions, 1); // b is 100% wrong
      expect(stats.totalPracticeAttempts, 6);
      expect(stats.totalIncorrectAttempts, 3);
      expect(stats.averageScore, closeTo(5.0, 0.01));
      expect(stats.practicedLabel, '2/3');
    });
  });

  group('collectWeakSamples', () {
    test('orders by incorrect ratio and truncates stem', () {
      final samples = collectWeakSamples(
        [
          _q(
            id: 'a',
            practiceCount: 4,
            incorrectCount: 1,
            content: 'easy',
          ),
          _q(
            id: 'b',
            practiceCount: 2,
            incorrectCount: 2,
            content: 'weak stem here',
          ),
          _q(id: 'c', practiceCount: 3, incorrectCount: 0),
        ],
        maxStemChars: 8,
      );
      expect(samples, hasLength(2));
      expect(samples.first.stem, 'weak st…');
      expect(samples.first.incorrectCount, 2);
    });
  });
}
