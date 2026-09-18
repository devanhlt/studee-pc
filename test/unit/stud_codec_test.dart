import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/data/file_storage/stud_codec.dart';

void main() {
  test('seal/open round-trips zip bytes', () {
    final zip = Uint8List.fromList(
      List<int>.generate(200, (i) => (i * 17 + 3) % 256),
    );
    final stud = StudCodec.seal(zip);
    expect(StudCodec.looksLikeStud(stud), isTrue);
    expect(stud, isNot(equals(zip)));
    final opened = StudCodec.open(stud);
    expect(opened, equals(zip));
  });

  test('tampered ciphertext fails integrity check', () {
    final zip = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    final stud = StudCodec.seal(zip);
    stud[stud.length ~/ 2] ^= 0xff;
    expect(() => StudCodec.open(stud), throwsA(isA<FormatException>()));
  });

  test('rejects non-stud bytes', () {
    expect(StudCodec.looksLikeStud(Uint8List.fromList([1, 2, 3])), isFalse);
    expect(
      () => StudCodec.open(Uint8List.fromList(List.filled(80, 0))),
      throwsA(isA<FormatException>()),
    );
  });
}
