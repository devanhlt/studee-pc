import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_grade.dart';

void main() {
  const choices = [
    PracticeChoice(label: 'A', content: r'c_3 = 22'),
    PracticeChoice(label: 'B', content: r'c_3 = -22'),
  ];

  test('grades A correct and B wrong', () {
    expect(
      PracticeMcqGrade.grade(
        answer: 'A. c_3 = 22',
        correctLabel: 'A',
        choices: choices,
      ),
      isTrue,
    );
    expect(
      PracticeMcqGrade.grade(
        answer: 'B. c_3 = -22',
        correctLabel: 'A',
        choices: choices,
      ),
      isFalse,
    );
  });

  test('sanitizes feedback that spoils next choices', () {
    final tip = PracticeMcqGrade.sanitizeFeedback(
      feedback: r'Chính xác! c3 = c2 = 22.',
      correct: true,
      nextCheck: r'Với c2 = 22, giá trị của c3 là bao nhiêu?',
      nextChoices: choices,
    );
    expect(tip, 'Chính xác!');
  });

  test('parses correct_label from turn json', () {
    final turn = PracticeTurnResponse.fromJson({
      'coach_message': '',
      'check_question': 'Chọn?',
      'check_choices': [
        {'label': 'A', 'content': '22'},
        {'label': 'B', 'content': '-22'},
      ],
      'correct_label': 'A',
      'is_complete': false,
    });
    expect(turn.correctLabel, 'A');
  });
}
