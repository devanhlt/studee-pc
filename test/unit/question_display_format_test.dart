import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/app/widgets/question_display_format.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';

void main() {
  group('QuestionDisplayFormat', () {
    test('converts Python nested list matrices to bmatrix LaTeX', () {
      const raw =
          'Cho 2 ma trận: A = [[-1,2],[1,3],[0,2]], B = [[-2,0],[1,-1],[-1,4]]. '
          'Tính 4A - 3B = ?';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.math,
      );
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
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.math,
      );
      expect(out, startsWith(r'$\begin{bmatrix}'));
      expect(out, contains(r'-14 & 12'));
      expect(out, contains(r'3 & 20'));
      expect(out, endsWith(r'\end{bmatrix}$'));
    });

    test('leaves existing LaTeX matrices alone', () {
      const raw = r'A = $\begin{bmatrix}1 & 2\\3 & 4\end{bmatrix}$';
      expect(
        QuestionDisplayFormat.enrich(raw, kind: SubjectFormatKind.math),
        raw,
      );
    });

    test('fromParsed joins stem and choices', () {
      final out = QuestionDisplayFormat.fromParsed(
        content: 'Tính A = [[1,0],[0,1]]',
        choices: [
          (label: 'A', content: '[[1,0],[0,1]]'),
          (label: 'B', content: '[[0,1],[1,0]]'),
        ],
        kind: SubjectFormatKind.math,
      );
      expect(out, contains(r'$A = \begin{bmatrix}'));
      expect(out, contains('A. \$'));
      expect(out, contains('B. \$'));
    });

    test('converts MATLAB-style paren matrices and A.AT', () {
      const raw =
          'Cho ma trận: A = ( 1 1 -2 ; 0 1 3 ). Tính A.AT = ?';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.math,
      );
      expect(out, contains(r'$A = \begin{bmatrix}'));
      expect(out, contains(r'1 & 1 & -2'));
      expect(out, contains(r'0 & 1 & 3'));
      expect(out, contains(r'$A A^{T}$'));
      expect(out, isNot(contains('( 1 1 -2')));
      expect(out, isNot(contains('A.AT')));
    });

    test('converts equation systems and x1 subscripts', () {
      const raw =
          'Giải hệ phương trình { x1 -3x2 +2x3 -x4 =2 ; 4x1 +x2 +3x3 -2x4 =1 ; 2x1 +7x2 -x3 =1 )';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.math,
      );
      expect(out, contains(r'\begin{cases}'));
      expect(out, contains(r'x_{1}'));
      expect(out, contains(r'x_{2}'));
      expect(out, contains(r'3x_{2}'));
      expect(out, isNot(contains('{ x1')));
      expect(out, isNot(contains('3x2')));
    });

    test('converts assignment list choices', () {
      const raw = 'x1=1,x2=1,x3=-1,x4=-6';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.math,
      );
      expect(out, contains(r'$x_{1}=1'));
      expect(out, contains(r'x_{4}=-6$'));
    });

    test('plain subject skips all math enrichers', () {
      const raw = 'A = [[1,0],[0,1]] và x1=2';
      expect(
        QuestionDisplayFormat.enrich(raw, kind: SubjectFormatKind.plain),
        raw,
      );
      expect(
        QuestionDisplayFormat.needsLatexPolish(
          raw,
          kind: SubjectFormatKind.plain,
        ),
        isFalse,
      );
    });

    test('does not turn C braces into cases', () {
      const raw = '''
Khi chạy chương trình sau trong ngôn ngữ lập trình C thì kết quả xuất ra màn hình là gì?
#include <stdio.h>
int tinhF(int n);
int tinhG(int n);
int main()
{ printf("%d",tinhG(2)); return 0; }
int tinhF(int n)
{ if(n==0)return 1; else return tinhF(n-1)+tinhG(n-1); }
''';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.code,
      );
      expect(out, isNot(contains(r'\begin{cases}')));
      expect(out, contains('printf'));
      expect(out, contains('n==0'));
      expect(out, contains('{'));
    });

    test('repairs code already corrupted by cases', () {
      const raw = r'''
#include <stdio.h>
int main()
\[\begin{cases}printf("%d",tinhG(2)) \\ return 0\end{cases}\]
''';
      final out = QuestionDisplayFormat.enrich(
        raw,
        kind: SubjectFormatKind.code,
      );
      expect(out, isNot(contains(r'\begin{cases}')));
      expect(out, contains('printf'));
      expect(out, contains('return 0'));
    });

    test('needsLatexPolish is false for C source', () {
      const raw = '#include <stdio.h>\nint main(){ return 0; }';
      expect(
        QuestionDisplayFormat.needsLatexPolish(
          raw,
          kind: SubjectFormatKind.math,
        ),
        isFalse,
      );
      expect(QuestionDisplayFormat.looksLikeSourceCode(raw), isTrue);
    });

    test('strips mathrm wrappers around code identifiers', () {
      const raw =
          r'for(int $\mathrm{j}$=0; $\mathrm{j}$<$\mathrm{n}$; $\mathrm{j}$++)';
      final out = QuestionDisplayFormat.repairSpuriousMathInCode(raw);
      expect(out, contains('for(int j=0; j<n; j++)'));
      expect(out, isNot(contains(r'\mathrm')));
      expect(out, isNot(contains(r'$')));
    });
  });

  group('inferSubjectFormatKind', () {
    test('math subjects', () {
      expect(
        inferSubjectFormatKind(name: 'Toán cao cấp'),
        SubjectFormatKind.math,
      );
      expect(
        inferSubjectFormatKind(name: 'Vật lý 1', icon: 'science'),
        SubjectFormatKind.math,
      );
    });

    test('code subjects', () {
      expect(
        inferSubjectFormatKind(name: 'Kỹ thuật lập trình'),
        SubjectFormatKind.code,
      );
      expect(
        inferSubjectFormatKind(name: 'Cấu trúc dữ liệu'),
        SubjectFormatKind.code,
      );
    });

    test('plain subjects', () {
      expect(
        inferSubjectFormatKind(name: 'Tiếng Anh'),
        SubjectFormatKind.plain,
      );
      expect(
        inferSubjectFormatKind(name: 'Lịch sử', icon: 'history_edu'),
        SubjectFormatKind.plain,
      );
    });
  });
}
