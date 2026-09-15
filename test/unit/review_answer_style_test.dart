import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/features/review/application/review_answer_style.dart';

void main() {
  test('strips A/B/C/D from đáp án đúng and keeps the raw content', () {
    const raw =
        'Triết học Mác hình thành từ sự vận động khách quan của lịch sử '
        'và vai trò chủ quan của con người. Đáp án đúng: A. Nhân tố chủ quan.';
    expect(
      stripMcqChoiceLetters(raw),
      'Triết học Mác hình thành từ sự vận động khách quan của lịch sử '
      'và vai trò chủ quan của con người. Nhân tố chủ quan.',
    );
  });

  test('strips đáp án B without a following period', () {
    expect(
      stripMcqChoiceLetters('Chưa đúng, đáp án B không khớp.'),
      'Chưa đúng, không khớp.',
    );
  });

  test('does not eat the c in class after Đáp án đúng là', () {
    const raw =
        'Đáp án đúng là class. Trong C++, từ khóa class được dùng '
        'để định nghĩa một lớp.';
    expect(stripMcqChoiceLetters(raw), raw);
    expect(stripMcqChoiceLetters(raw), startsWith('Đáp án đúng là class'));
  });

  test('still strips a bare A/B letter before the meaning', () {
    expect(
      stripMcqChoiceLetters('Đáp án đúng là A. class'),
      'class',
    );
    expect(
      stripMcqChoiceLetters('Đáp án đúng: B) public'),
      'public',
    );
  });
}
