/// Rewrites ôn-tập coach text so answers are meaning/content, not A/B/C/D.
String stripMcqChoiceLetters(String text) {
  var t = text.trim();
  if (t.isEmpty) return t;

  t = t.replaceAllMapped(
    RegExp(
      r'(Đáp án(?:\s*đúng)?(?:\s*là)?|Answer)\s*[:：]?\s*[A-Da-d]\s*[.)]?\s*',
      caseSensitive: false,
    ),
    (_) => '',
  );
  t = t.replaceAll(
    RegExp(
      r'\b(?:đáp án|lựa chọn|phương án)\s+[A-Da-d]\b',
      caseSensitive: false,
    ),
    '',
  );
  t = t.replaceAllMapped(
    RegExp(r'(^|[.!?]\s+)([A-Da-d])\s*[.)]\s+'),
    (m) => m[1]!,
  );
  t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  t = t.replaceAllMapped(
    RegExp(r' +([.,;:])'),
    (m) => m[1]!,
  );
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}
