import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';

void main() {
  group('PracticeTurnResponse.fromJson', () {
    test('parses start turn with two choices', () {
      final turn = PracticeTurnResponse.fromJson({
        'coach_message': 'Bước 1: xét định thức.',
        'check_question': 'det(A) khác 0 nghĩa là gì?',
        'check_choices': [
          {'label': 'A', 'content': 'A khả nghịch'},
          {'label': 'B', 'content': 'A suy biến'},
        ],
        'evaluation': null,
        'reveal': null,
        'is_complete': false,
        'final_summary': null,
      });
      expect(turn.coachMessage, contains('định thức'));
      expect(turn.checkQuestion, isNotNull);
      expect(turn.checkChoices, hasLength(2));
      expect(turn.checkChoices.first.label, 'A');
      expect(turn.checkChoices.last.content, 'A suy biến');
      expect(turn.isComplete, isFalse);
    });

    test('parses complete turn with mcq_tip', () {
      final turn = PracticeTurnResponse.fromJson({
        'coach_message': 'Xong.',
        'check_question': null,
        'evaluation': {'correct': true, 'feedback': 'Đúng'},
        'is_complete': true,
        'final_summary': 'Đáp án C.',
        'mcq_tip':
            'Mẹo: với ma trận, thử thay đáp án vào điều kiện det ≠ 0 để loại nhanh.',
      });
      expect(turn.isComplete, isTrue);
      expect(turn.checkQuestion, isNull);
      expect(turn.finalSummary, 'Đáp án C.');
      expect(turn.evaluation?.correct, isTrue);
      expect(turn.mcqTip, contains('det'));
    });
  });
}
