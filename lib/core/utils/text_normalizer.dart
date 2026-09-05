/// Vietnamese-aware text normalization for fingerprints and retrieval.
///
/// Exact matching **preserves diacritics** after Unicode NFC-style composition.
/// Use [accentFolded] only as a lower-ranked fallback signal.
abstract final class TextNormalizer {
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Leading MC label on answer text: `A.`, `B)`, `C -`, `D:`, …
  static final RegExp _choicePrefix = RegExp(
    r'^[A-Da-d]\s*[.\)\-–:：]\s*',
  );

  /// Bare answer that is only a choice letter.
  static final RegExp _bareChoiceLabel = RegExp(r'^[A-Da-d]$');

  /// Normalize general text: NFC composition, collapse whitespace, trim.
  /// Diacritics are preserved.
  static String normalize(String input) {
    final composed = toNfc(input);
    return composed.replaceAll(_whitespace, ' ').trim();
  }

  /// Normalize question stem for fingerprints and exact matching.
  static String normalizeQuestionText(String input) {
    return normalize(input);
  }

  /// Normalize a single multiple-choice content string (not the label).
  static String normalizeChoiceContent(String input) {
    return normalize(input);
  }

  /// Strip a leading `A.` / `B)` style prefix from answer text.
  static String stripChoicePrefix(String input) {
    var s = normalizeChoiceContent(input);
    for (var i = 0; i < 2; i++) {
      final next = s.replaceFirst(_choicePrefix, '').trim();
      if (next == s) break;
      s = next;
    }
    return s;
  }

  /// Compare answers for conflict / agreement — ignores A/B/C prefixes.
  ///
  /// Does not include the choice letter: `A. foo` and `C. foo` compare equal.
  static String normalizeAnswerForCompare(String input) {
    return stripChoicePrefix(input).toLowerCase();
  }

  /// True when the string is only a letter label after normalization.
  static bool isBareChoiceLabel(String input) {
    return _bareChoiceLabel.hasMatch(normalizeAnswerForCompare(input));
  }

  /// Lower-ranked fallback: remove Vietnamese tone/diacritic marks to ASCII.
  ///
  /// Do **not** use this for exact fingerprints or official matching.
  static String accentFolded(String input) {
    final normalized = normalize(input).toLowerCase();
    final buffer = StringBuffer();
    for (final unit in normalized.runes) {
      buffer.write(_foldMap[unit] ?? String.fromCharCode(unit));
    }
    return buffer.toString();
  }

  /// Compose common Vietnamese NFD sequences into NFC precomposed characters.
  ///
  /// Covers the Vietnamese Latin repertoire used in study materials. Characters
  /// already in NFC pass through unchanged.
  static String toNfc(String input) {
    // Fast path: if no combining marks, return as-is after a light pass.
    if (!_hasCombiningMark.hasMatch(input)) {
      return input;
    }

    // Decompose known precomposed chars then recompose via lookup of base+marks.
    // Practical approach for VI: map every known precomposed form is identity;
    // replace common base + tone combining sequences.
    final codeUnits = input.runes.toList();
    final out = StringBuffer();
    var i = 0;
    while (i < codeUnits.length) {
      final current = codeUnits[i];
      if (i + 1 < codeUnits.length) {
        final next = codeUnits[i + 1];
        final pair = _composePair[current]?[next];
        if (pair != null) {
          // May still have a second combining mark (tone on already marked vowel).
          if (i + 2 < codeUnits.length) {
            final third = codeUnits[i + 2];
            final triple = _composePair[pair]?[third];
            if (triple != null) {
              out.writeCharCode(triple);
              i += 3;
              continue;
            }
          }
          out.writeCharCode(pair);
          i += 2;
          continue;
        }
      }
      out.writeCharCode(current);
      i++;
    }
    return out.toString();
  }

  static final RegExp _hasCombiningMark = RegExp(r'[\u0300-\u036f]');

  /// base codepoint → (combining mark → composed)
  static final Map<int, Map<int, int>> _composePair = _buildComposeTable();

  static Map<int, Map<int, int>> _buildComposeTable() {
    const pairs = <String, String>{
      // a family
      'a\u0300': 'à', 'a\u0301': 'á', 'a\u0309': 'ả', 'a\u0303': 'ã', 'a\u0323': 'ạ',
      'a\u0306': 'ă', 'ă\u0300': 'ằ', 'ă\u0301': 'ắ', 'ă\u0309': 'ẳ', 'ă\u0303': 'ẵ',
      'ă\u0323': 'ặ', 'a\u0302': 'â', 'â\u0300': 'ầ', 'â\u0301': 'ấ', 'â\u0309': 'ẩ',
      'â\u0303': 'ẫ', 'â\u0323': 'ậ',
      // e family
      'e\u0300': 'è', 'e\u0301': 'é', 'e\u0309': 'ẻ', 'e\u0303': 'ẽ', 'e\u0323': 'ẹ',
      'e\u0302': 'ê', 'ê\u0300': 'ề', 'ê\u0301': 'ế', 'ê\u0309': 'ể', 'ê\u0303': 'ễ',
      'ê\u0323': 'ệ',
      // i family
      'i\u0300': 'ì', 'i\u0301': 'í', 'i\u0309': 'ỉ', 'i\u0303': 'ĩ', 'i\u0323': 'ị',
      // o family
      'o\u0300': 'ò', 'o\u0301': 'ó', 'o\u0309': 'ỏ', 'o\u0303': 'õ', 'o\u0323': 'ọ',
      'o\u0302': 'ô', 'ô\u0300': 'ồ', 'ô\u0301': 'ố', 'ô\u0309': 'ổ', 'ô\u0303': 'ỗ',
      'ô\u0323': 'ộ', 'o\u031b': 'ơ', 'ơ\u0300': 'ờ', 'ơ\u0301': 'ớ', 'ơ\u0309': 'ở',
      'ơ\u0303': 'ỡ', 'ơ\u0323': 'ợ',
      // u family
      'u\u0300': 'ù', 'u\u0301': 'ú', 'u\u0309': 'ủ', 'u\u0303': 'ũ', 'u\u0323': 'ụ',
      'u\u031b': 'ư', 'ư\u0300': 'ừ', 'ư\u0301': 'ứ', 'ư\u0309': 'ử', 'ư\u0303': 'ữ',
      'ư\u0323': 'ự',
      // y family
      'y\u0300': 'ỳ', 'y\u0301': 'ý', 'y\u0309': 'ỷ', 'y\u0303': 'ỹ', 'y\u0323': 'ỵ',
      // uppercase
      'A\u0300': 'À', 'A\u0301': 'Á', 'A\u0309': 'Ả', 'A\u0303': 'Ã', 'A\u0323': 'Ạ',
      'A\u0306': 'Ă', 'Ă\u0300': 'Ằ', 'Ă\u0301': 'Ắ', 'Ă\u0309': 'Ẳ', 'Ă\u0303': 'Ẵ',
      'Ă\u0323': 'Ặ', 'A\u0302': 'Â', 'Â\u0300': 'Ầ', 'Â\u0301': 'Ấ', 'Â\u0309': 'Ẩ',
      'Â\u0303': 'Ẫ', 'Â\u0323': 'Ậ',
      'E\u0300': 'È', 'E\u0301': 'É', 'E\u0309': 'Ẻ', 'E\u0303': 'Ẽ', 'E\u0323': 'Ẹ',
      'E\u0302': 'Ê', 'Ê\u0300': 'Ề', 'Ê\u0301': 'Ế', 'Ê\u0309': 'Ể', 'Ê\u0303': 'Ễ',
      'Ê\u0323': 'Ệ',
      'I\u0300': 'Ì', 'I\u0301': 'Í', 'I\u0309': 'Ỉ', 'I\u0303': 'Ĩ', 'I\u0323': 'Ị',
      'O\u0300': 'Ò', 'O\u0301': 'Ó', 'O\u0309': 'Ỏ', 'O\u0303': 'Õ', 'O\u0323': 'Ọ',
      'O\u0302': 'Ô', 'Ô\u0300': 'Ồ', 'Ô\u0301': 'Ố', 'Ô\u0309': 'Ổ', 'Ô\u0303': 'Ỗ',
      'Ô\u0323': 'Ộ', 'O\u031b': 'Ơ', 'Ơ\u0300': 'Ờ', 'Ơ\u0301': 'Ớ', 'Ơ\u0309': 'Ở',
      'Ơ\u0303': 'Ỡ', 'Ơ\u0323': 'Ợ',
      'U\u0300': 'Ù', 'U\u0301': 'Ú', 'U\u0309': 'Ủ', 'U\u0303': 'Ũ', 'U\u0323': 'Ụ',
      'U\u031b': 'Ư', 'Ư\u0300': 'Ừ', 'Ư\u0301': 'Ứ', 'Ư\u0309': 'Ử', 'Ư\u0303': 'Ữ',
      'Ư\u0323': 'Ự',
      'Y\u0300': 'Ỳ', 'Y\u0301': 'Ý', 'Y\u0309': 'Ỷ', 'Y\u0303': 'Ỹ', 'Y\u0323': 'Ỵ',
    };

    final table = <int, Map<int, int>>{};
    for (final entry in pairs.entries) {
      final key = entry.key;
      final runes = key.runes.toList();
      if (runes.length != 2) continue;
      table.putIfAbsent(runes[0], () => <int, int>{})[runes[1]] =
          entry.value.runes.first;
    }
    return table;
  }

  static final Map<int, String> _foldMap = {
    // a
    'à'.runes.first: 'a', 'á'.runes.first: 'a', 'ả'.runes.first: 'a',
    'ã'.runes.first: 'a', 'ạ'.runes.first: 'a', 'ă'.runes.first: 'a',
    'ằ'.runes.first: 'a', 'ắ'.runes.first: 'a', 'ẳ'.runes.first: 'a',
    'ẵ'.runes.first: 'a', 'ặ'.runes.first: 'a', 'â'.runes.first: 'a',
    'ầ'.runes.first: 'a', 'ấ'.runes.first: 'a', 'ẩ'.runes.first: 'a',
    'ẫ'.runes.first: 'a', 'ậ'.runes.first: 'a',
    // e
    'è'.runes.first: 'e', 'é'.runes.first: 'e', 'ẻ'.runes.first: 'e',
    'ẽ'.runes.first: 'e', 'ẹ'.runes.first: 'e', 'ê'.runes.first: 'e',
    'ề'.runes.first: 'e', 'ế'.runes.first: 'e', 'ể'.runes.first: 'e',
    'ễ'.runes.first: 'e', 'ệ'.runes.first: 'e',
    // i
    'ì'.runes.first: 'i', 'í'.runes.first: 'i', 'ỉ'.runes.first: 'i',
    'ĩ'.runes.first: 'i', 'ị'.runes.first: 'i',
    // o
    'ò'.runes.first: 'o', 'ó'.runes.first: 'o', 'ỏ'.runes.first: 'o',
    'õ'.runes.first: 'o', 'ọ'.runes.first: 'o', 'ô'.runes.first: 'o',
    'ồ'.runes.first: 'o', 'ố'.runes.first: 'o', 'ổ'.runes.first: 'o',
    'ỗ'.runes.first: 'o', 'ộ'.runes.first: 'o', 'ơ'.runes.first: 'o',
    'ờ'.runes.first: 'o', 'ớ'.runes.first: 'o', 'ở'.runes.first: 'o',
    'ỡ'.runes.first: 'o', 'ợ'.runes.first: 'o',
    // u
    'ù'.runes.first: 'u', 'ú'.runes.first: 'u', 'ủ'.runes.first: 'u',
    'ũ'.runes.first: 'u', 'ụ'.runes.first: 'u', 'ư'.runes.first: 'u',
    'ừ'.runes.first: 'u', 'ứ'.runes.first: 'u', 'ử'.runes.first: 'u',
    'ữ'.runes.first: 'u', 'ự'.runes.first: 'u',
    // y / d
    'ỳ'.runes.first: 'y', 'ý'.runes.first: 'y', 'ỷ'.runes.first: 'y',
    'ỹ'.runes.first: 'y', 'ỵ'.runes.first: 'y', 'đ'.runes.first: 'd',
  };
}
