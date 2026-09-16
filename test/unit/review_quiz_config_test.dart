import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/features/review/application/review_quiz_config.dart';

Question _q(String id, {int practiceCount = 0}) {
  final now = DateTime.utc(2026, 1, 1);
  return Question(
    id: id,
    knowledgeUnitId: 'ku',
    questionType: QuestionType.multipleChoice,
    content: 'Q $id',
    normalizedContent: 'q $id',
    questionFingerprint: 'fp-$id',
    verificationStatus: VerificationStatus.unreviewed,
    createdAt: now,
    updatedAt: now,
    practiceCount: practiceCount,
  );
}

void main() {
  group('buildShuffledQuizSet', () {
    test('returns empty for empty source', () {
      expect(buildShuffledQuizSet(const []), isEmpty);
    });

    test('pads with duplicates when fewer than 40', () {
      final source = [_q('a'), _q('b'), _q('c')];
      final out = buildShuffledQuizSet(
        source,
        size: 40,
        random: Random(1),
      );
      expect(out, hasLength(40));
      expect(out.map((q) => q.id).toSet(), {'a', 'b', 'c'});
    });

    test('takes least-practiced questions first', () {
      final source = [
        _q('high', practiceCount: 5),
        _q('mid', practiceCount: 2),
        _q('low-a', practiceCount: 0),
        _q('low-b', practiceCount: 0),
        for (var i = 0; i < 40; i++) _q('other-$i', practiceCount: 9),
      ];
      final out = buildShuffledQuizSet(
        source,
        size: 40,
        random: Random(1),
      );
      expect(out, hasLength(40));
      final firstFourIds = out.take(4).map((q) => q.id).toSet();
      expect(firstFourIds.contains('low-a'), isTrue);
      expect(firstFourIds.contains('low-b'), isTrue);
      expect(firstFourIds.contains('mid'), isTrue);
      expect(firstFourIds.contains('high'), isTrue);
      expect(out.first.practiceCount, 0);
      expect(out[2].practiceCount, lessThanOrEqualTo(out[3].practiceCount));
      // Never pick a high-count question before all lower counts are used.
      final highIndex = out.indexWhere((q) => q.id == 'high');
      final midIndex = out.indexWhere((q) => q.id == 'mid');
      expect(midIndex, lessThan(highIndex));
    });

    test('takes exactly 40 from a larger pool', () {
      final source = [for (var i = 0; i < 60; i++) _q('$i')];
      final out = buildShuffledQuizSet(
        source,
        size: 40,
        random: Random(42),
      );
      expect(out, hasLength(40));
      expect(out.map((q) => q.id).toSet(), hasLength(40));
    });
  });

  group('formatQuizCountdown', () {
    test('formats mm:ss', () {
      expect(formatQuizCountdown(const Duration(minutes: 30)), '30:00');
      expect(formatQuizCountdown(const Duration(minutes: 4, seconds: 9)), '04:09');
      expect(formatQuizCountdown(Duration.zero), '00:00');
    });
  });

  test('quiz config defaults', () {
    expect(ReviewQuizConfig.questionCount, 40);
    expect(ReviewQuizConfig.duration, const Duration(minutes: 30));
  });
}
