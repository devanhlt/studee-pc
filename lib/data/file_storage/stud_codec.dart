import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Encrypted Studee subject pack (`.stud`).
///
/// Wire format:
/// - magic `STUD01` (6 bytes)
/// - salt (16)
/// - iv (16)
/// - AES-256-CBC PKCS7 ciphertext of a subject ZIP
/// - HMAC-SHA256 (32) over salt || iv || ciphertext
abstract final class StudCodec {
  static const magic = [0x53, 0x54, 0x55, 0x44, 0x30, 0x31]; // STUD01
  static const extension = 'stud';
  static const fileExtension = '.stud';

  static const _saltLen = 16;
  static const _ivLen = 16;
  static const _hmacLen = 32;
  static const _headerLen = 6 + _saltLen + _ivLen;

  /// App-scoped key material (not a user password). Keeps `.stud` opaque.
  static final _keyMaterial = utf8.encode('studee.subject.pack.v1');
  static final _macMaterial = utf8.encode('studee.subject.pack.v1.mac');

  static bool looksLikeStud(List<int> bytes) {
    if (bytes.length < _headerLen + _hmacLen + 1) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  static Uint8List seal(Uint8List zipBytes, {Random? random}) {
    final rng = random ?? Random.secure();
    final salt = Uint8List(_saltLen);
    final iv = Uint8List(_ivLen);
    for (var i = 0; i < _saltLen; i++) {
      salt[i] = rng.nextInt(256);
    }
    for (var i = 0; i < _ivLen; i++) {
      iv[i] = rng.nextInt(256);
    }

    final key = _deriveKey(_keyMaterial, salt);
    final cipherBytes = _aesCbcEncrypt(key: key, iv: iv, plain: zipBytes);
    final macKey = _deriveKey(_macMaterial, salt);
    final mac = _hmacSha256(
      key: macKey,
      message: Uint8List.fromList([...salt, ...iv, ...cipherBytes]),
    );

    return Uint8List.fromList([
      ...magic,
      ...salt,
      ...iv,
      ...cipherBytes,
      ...mac,
    ]);
  }

  static Uint8List open(Uint8List studBytes) {
    if (!looksLikeStud(studBytes)) {
      throw const FormatException('Not a Studee .stud file');
    }
    final salt = Uint8List.fromList(
      studBytes.sublist(6, 6 + _saltLen),
    );
    final iv = Uint8List.fromList(
      studBytes.sublist(6 + _saltLen, _headerLen),
    );
    final cipherEnd = studBytes.length - _hmacLen;
    if (cipherEnd <= _headerLen) {
      throw const FormatException('Corrupt .stud file');
    }
    final cipherBytes = Uint8List.fromList(
      studBytes.sublist(_headerLen, cipherEnd),
    );
    final mac = Uint8List.fromList(studBytes.sublist(cipherEnd));

    final macKey = _deriveKey(_macMaterial, salt);
    final expected = _hmacSha256(
      key: macKey,
      message: Uint8List.fromList([...salt, ...iv, ...cipherBytes]),
    );
    if (!_constantTimeEquals(mac, expected)) {
      throw const FormatException('Invalid .stud integrity check');
    }

    final key = _deriveKey(_keyMaterial, salt);
    return _aesCbcDecrypt(key: key, iv: iv, cipher: cipherBytes);
  }

  static Uint8List _deriveKey(List<int> material, Uint8List salt) {
    return Uint8List.fromList(
      sha256.convert([...material, ...salt]).bytes,
    );
  }

  static Uint8List _hmacSha256({
    required Uint8List key,
    required Uint8List message,
  }) {
    final hmac = Hmac(sha256, key);
    return Uint8List.fromList(hmac.convert(message).bytes);
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Uint8List _aesCbcEncrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List plain,
  }) {
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key), iv),
          null,
        ),
      );
    return cipher.process(plain);
  }

  static Uint8List _aesCbcDecrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List cipher,
  }) {
    final engine = PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key), iv),
          null,
        ),
      );
    return engine.process(cipher);
  }
}
