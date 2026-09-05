import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';

/// Deterministic fingerprints for question matching.
abstract final class Fingerprints {
  /// SHA-256 hex digest of arbitrary UTF-8 content.
  static String contentHash(String content) {
    final digest = sha256.convert(utf8.encode(content));
    return digest.toString();
  }

  /// Order-independent fingerprint of normalized choice contents.
  ///
  /// Labels are ignored — only choice body text participates.
  static String choiceSetFingerprint(Iterable<String> choiceContents) {
    final normalized = choiceContents
        .map(TextNormalizer.normalizeChoiceContent)
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort();
    return contentHash(normalized.join('\u{1f}'));
  }

  /// Fingerprint from normalized question text plus order-independent choices.
  static String questionFingerprint({
    required String questionText,
    required Iterable<String> choiceContents,
  }) {
    final q = TextNormalizer.normalizeQuestionText(questionText);
    final choices = choiceSetFingerprint(choiceContents);
    return contentHash('$q\u{1e}$choices');
  }

  /// Hash of a canonical semantic key (normalized, collapsed whitespace).
  ///
  /// Operator spacing is stripped so `1+1` and `1 + 1` share a fingerprint.
  static String semanticFingerprint(String semanticKey) {
    final key = TextNormalizer.normalizeQuestionText(semanticKey)
        .replaceAll(RegExp(r'\s*([+\-*/^=])\s*'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return contentHash('sem\u{1e}$key');
  }
}
