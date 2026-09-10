import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/data/mathpix/mathpix_text_normalizer.dart';

void main() {
  group('MathpixTextNormalizer', () {
    test('rewrites dual A/B tabular into pmatrix', () {
      const raw = r'''
Câu 5:

Cho 2 ma trận:

\begin{tabular}[t]{|l|l|l|l|l|l|l|l|}
\hline & 1 & 2 & 0 & & 2 & 1 & -1 \\
\hline $\mathrm{A}=($ & 4 & 5 & 3 & ),B=( & 3 & 4 & 2 ) \\
\hline & 2 & -3 & 1 & & 5 & -2 & 3 \\
\hline
\end{tabular}

Tính $\mathbf{2 A}-\mathbf{3 B}=$ ?
◯ A.

\begin{tabular}[t]{|l|l|l|}
\hline 1 & -4 & 2 \\
\hline ( -6 & -7 & -5 ) \\
\hline 4 & 5 & 3 \\
\hline
\end{tabular}
◯ B.

\begin{tabular}[t]{|l|l|l|}
\hline 1 & -4 & -2 \\
\hline ( -6 & -7 & -5 ) \\
\hline 4 & -5 & 3 \\
\hline
\end{tabular}
''';

      final out = MathpixTextNormalizer.normalize(raw);
      expect(out, contains(r'\begin{pmatrix}'));
      expect(out, contains('A ='));
      expect(out, contains('B ='));
      expect(out, isNot(contains(r'\begin{tabular}')));
      expect(out, contains('A.'));
      expect(out, isNot(contains('◯')));
      // A matrix values
      expect(out, contains(r'1 & 2 & 0'));
      expect(out, contains(r'4 & 5 & 3'));
      expect(out, contains(r'2 & -3 & 1'));
      // B matrix values
      expect(out, contains(r'2 & 1 & -1'));
      expect(out, contains(r'3 & 4 & 2'));
      expect(out, contains(r'5 & -2 & 3'));
    });

    test('leaves plain prose alone', () {
      const raw = r'Khi nào $\det(A) \neq 0$?';
      expect(MathpixTextNormalizer.normalize(raw), raw);
    });

    test('plain A=(...),B=(...) with tabs becomes two matrices', () {
      const raw = '''
Cho 2 ma trận:
A=( 
1	2	0
4	5	3
2	-3	1
 ),B=( 
2	1	-1
3	4	2
5	-2	3
 )
Tính 2A-3B
''';
      final out = MathpixTextNormalizer.normalize(raw);
      expect(out, contains('A ='));
      expect(out, contains('B ='));
      expect(
        RegExp(r'\\begin\{pmatrix\}').allMatches(out).length,
        greaterThanOrEqualTo(2),
      );
      expect(out, contains(r'1 & 2 & 0'));
      expect(out, contains(r'2 & 1 & -1'));
      // Must not be one 3×6 matrix.
      expect(out, isNot(contains(r'1 & 2 & 0 & 2 & 1 & -1')));
    });

    test('wide numeric tabular without clean labels still splits A|B', () {
      const raw = r'''
\begin{tabular}{|l|l|l|l|l|l|}
\hline 1 & 2 & 0 & 2 & 1 & -1 \\
\hline 4 & 5 & 3 & 3 & 4 & 2 \\
\hline 2 & -3 & 1 & 5 & -2 & 3 \\
\hline
\end{tabular}
''';
      final out = MathpixTextNormalizer.normalize(raw);
      expect(
        RegExp(r'\\begin\{pmatrix\}').allMatches(out).length,
        2,
      );
      expect(out, isNot(contains(r'1 & 2 & 0 & 2 & 1 & -1')));
    });
  });
}
