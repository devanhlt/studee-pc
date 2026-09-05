import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';

void main() {
  group('Fingerprints', () {
    const question = 'Ma trận A khả nghịch khi nào?';

    test('same question + reordered choices → same fingerprint', () {
      final a = Fingerprints.questionFingerprint(
        questionText: question,
        choiceContents: const [
          'det(A) = 0',
          'det(A) khác không',
          'rank(A) < n',
          'A = 0',
        ],
      );
      final b = Fingerprints.questionFingerprint(
        questionText: question,
        choiceContents: const [
          'A = 0',
          'det(A) khác không',
          'det(A) = 0',
          'rank(A) < n',
        ],
      );
      expect(a, b);
      expect(a.length, 64); // sha256 hex
    });

    test('different question text → different fingerprint', () {
      final a = Fingerprints.questionFingerprint(
        questionText: question,
        choiceContents: const ['định thức khác không', 'định thức bằng 0'],
      );
      final b = Fingerprints.questionFingerprint(
        questionText: 'Ma trận A suy biến khi nào?',
        choiceContents: const ['định thức khác không', 'định thức bằng 0'],
      );
      expect(a, isNot(b));
    });

    test('choice set fingerprint is order-independent', () {
      final a = Fingerprints.choiceSetFingerprint(const [
        'định thức khác không',
        'det(A) = 0',
        'A không khả nghịch',
      ]);
      final b = Fingerprints.choiceSetFingerprint(const [
        'A không khả nghịch',
        'định thức khác không',
        'det(A) = 0',
      ]);
      expect(a, b);

      final different = Fingerprints.choiceSetFingerprint(const [
        'định thức bằng 0',
        'det(A) = 0',
        'A không khả nghịch',
      ]);
      expect(a, isNot(different));
    });

    test('whitespace-normalized question text yields same fingerprint', () {
      final a = Fingerprints.questionFingerprint(
        questionText: 'Ma trận  A',
        choiceContents: const ['x', 'y'],
      );
      final b = Fingerprints.questionFingerprint(
        questionText: '  Ma trận A  ',
        choiceContents: const ['y', 'x'],
      );
      expect(a, b);
    });

    test('semanticFingerprint.v1 hashing helper', () {
      expect(
        Fingerprints.semanticFingerprint('1+1'),
        Fingerprints.semanticFingerprint(' 1 + 1 '),
      );
      expect(
        Fingerprints.semanticFingerprint('1+1'),
        isNot(Fingerprints.semanticFingerprint('1+2')),
      );
    });
  });
}
