/// Heuristic MCQ strategy tips for practice mode (Vietnamese UI).
class PracticeMcqTips {
  PracticeMcqTips._();

  static const _general = <String>[
    'Mẹo: thử ngược từ các đáp án thay vì giải xuôi cả bài.',
    'Mẹo: ước lượng trước để loại đáp án, chỉ tính chi tiết khi cần.',
    'Mẹo: đáp án có độ lớn hoặc dạng vô lý thì loại ngay.',
    'Mẹo: câu khó nên tạm bỏ qua, làm xong phần dễ rồi quay lại.',
    'Mẹo: đừng chọn theo cảm giác, ví dụ “câu dài nhất thường đúng”.',
  ];

  /// Pick one tip matching [question] / [choices] / [context]; rotates by [seed].
  ///
  /// When [includeSnippet] is false, returns only the tip line (use when the
  /// full question is already visible, e.g. Ôn tập Giải đề).
  static String pick({
    required String question,
    required List<String> choices,
    String context = '',
    int seed = 0,
    bool includeSnippet = true,
  }) {
    final hay = '$question\n${choices.join('\n')}\n$context'.toLowerCase();
    final matched = <String>[];
    final snippet = includeSnippet
        ? _snippet(question.isNotEmpty ? question : context)
        : null;

    void addIf(bool cond, String tip) {
      if (cond) matched.add(tip);
    }

    addIf(
      _hasAny(hay, const ['thay', 'plug', 'phương trình', 'equation', 'nghiệm']),
      'Mẹo: thay lần lượt từng đáp án vào đề để kiểm tra nhanh.',
    );
    addIf(
      _hasAny(hay, const [
        'đặc biệt',
        'special value',
        'thử x',
        'thay x',
        'x = 0',
        'x=0',
        'x = 1',
        'x=-1',
      ]),
      'Mẹo: thử giá trị đơn giản như 0, 1, −1 để loại đáp án sai.',
    );
    addIf(
      _hasAny(hay, const [
        'dấu',
        'sign',
        'dương',
        'âm',
        'positive',
        'negative',
        'bằng 0',
        'khác 0',
      ]),
      'Mẹo: xác định đáp án phải dương, âm hay bằng 0 trước khi tính chi tiết.',
    );
    addIf(
      _hasAny(hay, const [
        'nguyên',
        'chẵn',
        'lẻ',
        'hữu tỉ',
        'integer',
        'parity',
        'rational',
      ]),
      'Mẹo: kiểm tra tính chẵn/lẻ, nguyên hay hữu tỉ theo yêu cầu đề.',
    );
    addIf(
      _hasAny(hay, const [
        'đơn vị',
        'unit',
        'mét',
        'kg',
        'giây',
        'newton',
        'joule',
      ]),
      'Mẹo: dùng phân tích thứ nguyên để loại đáp án sai đơn vị.',
    );
    addIf(
      _hasAny(hay, const [
        'đối xứng',
        'bất biến',
        'symmetry',
        'invariance',
      ]),
      'Mẹo: tận dụng đối xứng / bất biến của bài để loại nhanh.',
    );
    addIf(
      _hasAny(hay, const [
        'ma trận',
        'matrix',
        'định thức',
        'det',
        'hạng',
        'rank',
        'tích phân',
        'integral',
      ]),
      'Mẹo: dùng máy tính để thử giá trị, giải phương trình hoặc tính ma trận.',
    );
    addIf(
      _hasAny(hay, const [
        'miền',
        'domain',
        'xác định',
        'log',
        '√',
        'căn',
        'mẫu số',
      ]),
      'Mẹo: loại đáp án nằm ngoài miền xác định.',
    );
    addIf(
      _hasAny(hay, const ['chứng minh', 'đúng hay sai', 'true', 'false', 'luôn']),
      'Mẹo: tìm phản ví dụ để bác bỏ phát biểu sai.',
    );
    addIf(
      _choicesLookClose(choices),
      'Mẹo: chỉ tập trung vào dấu, hệ số hoặc hạng tử khác nhau giữa các lựa chọn.',
    );
    addIf(
      _choicesLookFar(choices),
      'Mẹo: ước lượng thô khi các đáp án cách nhau xa.',
    );
    addIf(
      choices.length >= 2 && !_choicesLookFar(choices),
      'Mẹo: tính chính xác hơn khi các đáp án gần nhau.',
    );
    addIf(
      _hasAny(hay, const ['tương đương', 'equivalent', '⇔']),
      'Mẹo: nhận diện các lựa chọn tương đương toán học để gộp lại.',
    );

    final pool = matched.isNotEmpty ? matched : _general;
    final base = pool[seed.abs() % pool.length];
    if (!includeSnippet || snippet == null) return base;
    if (matched.isEmpty) {
      return 'Mẹo: với đề “$snippet”, hãy thay lần lượt các đáp án vào điều kiện chính để chọn nhanh.';
    }
    return '$base Áp dụng với đề này: $snippet';
  }

  /// Longer tip (2–4 sentences) with strategy only — never restate the stem
  /// or correct answer (those are already on screen in Giải đề).
  static String pickDetailed({
    required String question,
    required List<String> choices,
    String context = '',
    String? correctAnswerMeaning,
    int seed = 0,
  }) {
    final base = pick(
      question: question,
      choices: choices,
      context: context,
      seed: seed,
      includeSnippet: false,
    );
    final hay = '$question\n${choices.join('\n')}\n$context'.toLowerCase();
    final parts = <String>[base];

    if (_hasAny(hay, const ['ma trận', 'matrix', 'hạng', 'rank', 'định thức', 'det'])) {
      parts.add(
        'Với đề ma trận, hãy nhìn điều kiện đề hỏi (hạng, khả nghịch, định thức…) '
        'rồi thử các giá trị đặc biệt của tham số (thường là 0 hoặc 1) để loại nhanh '
        'trước khi khai triển hết.',
      );
    } else if (_hasAny(hay, const ['phương trình', 'nghiệm', 'equation'])) {
      parts.add(
        'Thay lần lượt từng lựa chọn vào điều kiện chính của đề; lựa chọn nào '
        'làm phương trình/điều kiện đúng thì giữ, còn lại loại.',
      );
    } else if (choices.length >= 2) {
      parts.add(
        'So sánh các lựa chọn: tập trung vào chỗ khác nhau (dấu, miền, đẳng thức), '
        'loại đáp án mâu thuẫn với điều kiện đề rồi mới tính chi tiết.',
      );
    }

    parts.add(
      'Sau khi loại, kiểm tra lại một lần xem lựa chọn còn lại có thỏa '
      'đúng điều kiện đề hỏi không.',
    );

    // correctAnswerMeaning is intentionally unused in the tip text — the
    // feedback line already shows the answer; avoid duplicating it here.
    return withoutQuestionEcho(parts.join(' '), question);
  }

  /// Drop pasted question / “Áp dụng với đề này: …” tails from tip text.
  static String withoutQuestionEcho(String tip, String question) {
    var t = tip.trim();
    // Strip common re-paste prefixes and everything after.
    t = t.replaceAll(
      RegExp(r'\s*Áp dụng với đề này\s*[:：].*$', caseSensitive: false),
      '',
    );
    t = t.replaceAll(
      RegExp(r'\s*với đề\s*[“"][^”"]+[”"].*$', caseSensitive: false),
      '',
    );

    final stem = question.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (stem.length >= 24) {
      // If tip contains a long chunk of the stem, cut from that point.
      final probeLen = stem.length > 48 ? 48 : stem.length;
      final probe = stem.substring(0, probeLen);
      final idx = t.indexOf(probe);
      if (idx >= 8) {
        t = t.substring(0, idx).trim();
      }
    }
    // Also cut at "Câu N" restarts that look like a stem dump.
    t = t.replaceAll(RegExp(r'\s*Câu\s+\d+\s+Cho\b.*$', caseSensitive: false), '');
    return t.trim();
  }

  /// Full question text for the tip — never mid-cut with “…”.
  static String? _snippet(String raw) {
    final t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length < 12) return null;
    return t;
  }

  static bool _hasAny(String hay, List<String> keys) =>
      keys.any((k) => hay.contains(k.toLowerCase()));

  static bool _choicesLookClose(List<String> choices) {
    if (choices.length < 2) return false;
    final a = choices[0].replaceAll(RegExp(r'\s+'), '');
    final b = choices[1].replaceAll(RegExp(r'\s+'), '');
    if (a.isEmpty || b.isEmpty) return false;
    final shared = a.length < b.length
        ? a.split('').where(b.contains).length
        : b.split('').where(a.contains).length;
    final maxLen = a.length > b.length ? a.length : b.length;
    return shared / maxLen > 0.55;
  }

  static bool _choicesLookFar(List<String> choices) {
    if (choices.length < 2) return false;
    final nums = <double>[];
    for (final c in choices) {
      for (final m in RegExp(r'-?\d+(?:\.\d+)?').allMatches(c)) {
        nums.add(double.tryParse(m.group(0)!) ?? 0);
      }
    }
    if (nums.length < 2) return false;
    nums.sort();
    return (nums.last - nums.first).abs() >= 10;
  }
}
