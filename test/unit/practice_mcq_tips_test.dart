import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/features/practice/application/practice_mcq_tips.dart';

void main() {
  test('picks matrix-related tip for determinant question', () {
    final tip = PracticeMcqTips.pick(
      question: 'Ma trận A khả nghịch khi và chỉ khi',
      choices: const ['A. det(A) = 0', 'B. det(A) ≠ 0'],
      context: 'định thức ma trận',
      seed: 0,
    );
    expect(tip.startsWith('Mẹo:'), isTrue);
    expect(tip.toLowerCase(), contains('máy tính'));
  });

  test('falls back to general tip', () {
    final tip = PracticeMcqTips.pick(
      question: 'Chọn đáp án đúng',
      choices: const ['A. x', 'B. y'],
      seed: 1,
    );
    expect(tip.startsWith('Mẹo:'), isTrue);
  });
}
