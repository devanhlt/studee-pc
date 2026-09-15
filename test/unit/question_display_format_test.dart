import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/app/widgets/question_display_format.dart';

void main() {
  group('QuestionDisplayFormat', () {
    test('converts Python nested list matrices to bmatrix LaTeX', () {
      const raw =
          'Cho 2 ma trận: A = [[-1,2],[1,3],[0,2]], B = [[-2,0],[1,-1],[-1,4]]. '
          'Tính 4A - 3B = ?';
      final out = QuestionDisplayFormat.enrich(raw);
      expect(out, contains(r'$A = \begin{bmatrix}'));
      expect(out, contains(r'-1 & 2'));
      expect(out, contains(r'1 & 3'));
      expect(out, contains(r'0 & 2'));
      expect(out, contains(r'\end{bmatrix}$'));
      expect(out, contains(r'$B = \begin{bmatrix}'));
      expect(out, isNot(contains('[[-1,2]')));
    });

    test('converts choice-only matrix literal', () {
      const raw = '[[-14,12],[1,5],[3,20]]';
      final out = QuestionDisplayFormat.enrich(raw);
      expect(out, startsWith(r'$\begin{bmatrix}'));
      expect(out, contains(r'-14 & 12'));
      expect(out, contains(r'3 & 20'));
      expect(out, endsWith(r'\end{bmatrix}$'));
    });

    test('leaves existing LaTeX matrices alone', () {
      const raw = r'A = $\begin{bmatrix}1 & 2\\3 & 4\end{bmatrix}$';
      expect(QuestionDisplayFormat.enrich(raw), raw);
    });

    test('fromParsed joins stem and choices', () {
      final out = QuestionDisplayFormat.fromParsed(
        content: 'Tính A = [[1,0],[0,1]]',
        choices: [
          (label: 'A', content: '[[1,0],[0,1]]'),
          (label: 'B', content: '[[0,1],[1,0]]'),
        ],
      );
      expect(out, contains(r'$A = \begin{bmatrix}'));
      expect(out, contains('A. \$'));
      expect(out, contains('B. \$'));
    });

    test('converts MATLAB-style paren matrices and A.AT', () {
      const raw =
          'Cho ma trận: A = ( 1 1 -2 ; 0 1 3 ). Tính A.AT = ?';
      final out = QuestionDisplayFormat.enrich(raw);
      expect(out, contains(r'$A = \begin{bmatrix}'));
      expect(out, contains(r'1 & 1 & -2'));
      expect(out, contains(r'0 & 1 & 3'));
      expect(out, contains(r'$A A^{T}$'));
      expect(out, isNot(contains('( 1 1 -2')));
      expect(out, isNot(contains('A.AT')));
    });

    test('converts MATLAB choice matrices', () {
      const raw = '( 6 -5 ; -5 10 )';
      final out = QuestionDisplayFormat.enrich(raw);
      expect(out, startsWith(r'$\begin{bmatrix}'));
      expect(out, contains(r'6 & -5'));
      expect(out, contains(r'-5 & 10'));
    });
  });
}
