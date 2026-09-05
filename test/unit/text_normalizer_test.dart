import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    test('NFC / normalize preserves Vietnamese diacritics', () {
      const name = 'Nguyễn';
      expect(TextNormalizer.normalize(name), 'Nguyễn');
      expect(TextNormalizer.normalizeQuestionText(name), contains('ễ'));
      expect(TextNormalizer.normalizeChoiceContent('định thức'), 'định thức');

      // NFD base + tone should compose; diacritics remain present.
      final nfd = 'Nguye\u0303n'; // e + combining tilde → ẽ family path
      final nfc = TextNormalizer.toNfc(nfd);
      expect(nfc.contains('\u0303'), isFalse);
      expect(TextNormalizer.normalize('Nguyễn Văn A'), 'Nguyễn Văn A');
    });

    test('collapses whitespace and trims', () {
      expect(
        TextNormalizer.normalize('  ma trận   định thức  \n'),
        'ma trận định thức',
      );
      expect(
        TextNormalizer.normalizeQuestionText('\tA\n\nB  C '),
        'A B C',
      );
    });

    test('accentFolded removes tones (đường → duong style)', () {
      expect(TextNormalizer.accentFolded('đường'), 'duong');
      expect(TextNormalizer.accentFolded('Định thức'), 'dinh thuc');
      expect(TextNormalizer.accentFolded('Nguyễn'), 'nguyen');
      expect(TextNormalizer.accentFolded('  Ma  Trận  '), 'ma tran');
    });

    test('normalizeAnswerForCompare strips A/B/C prefixes', () {
      expect(
        TextNormalizer.normalizeAnswerForCompare('A. định thức khác không'),
        TextNormalizer.normalizeAnswerForCompare('C) định thức khác không'),
      );
      expect(
        TextNormalizer.normalizeAnswerForCompare('B - ma trận khả nghịch'),
        'ma trận khả nghịch',
      );
      expect(TextNormalizer.stripChoicePrefix('D: foo'), 'foo');
      expect(TextNormalizer.isBareChoiceLabel('A'), isTrue);
      expect(TextNormalizer.isBareChoiceLabel('A. foo'), isFalse);
    });

    test('exact normalize must NOT strip diacritics', () {
      const withTones = 'đường đi tới ma trận';
      final exact = TextNormalizer.normalize(withTones);
      expect(exact, 'đường đi tới ma trận');
      expect(exact, isNot(TextNormalizer.accentFolded(withTones)));
      expect(exact.contains('ư'), isTrue);
      expect(exact.contains('ờ'), isTrue);
      expect(exact.contains('ậ'), isTrue);
    });
  });
}
