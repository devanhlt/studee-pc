/// Formats answers for the UI without picking an A/B/C option for the user.
///
/// Choice order often changes between sources; show meaning/content so the
/// learner can match it to their own options.
class AnswerDisplay {
  const AnswerDisplay._();

  static final RegExp _bareChoiceLetter = RegExp(
    r'^[A-Da-d]([.\)\-–:：]\s*)?$',
  );

  /// True when [value] is only a choice letter (e.g. `C`, `A.`).
  static bool isChoiceLetterOnly(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return false;
    return _bareChoiceLetter.hasMatch(t);
  }

  /// Prefer full answer content; never return a bare A/B/C letter.
  static String contentOnly({
    String? label,
    String? content,
    String? shortAnswer,
  }) {
    final body = content?.trim();
    if (body != null && body.isNotEmpty && !isChoiceLetterOnly(body)) {
      return body;
    }
    final short = shortAnswer?.trim();
    if (short != null && short.isNotEmpty && !isChoiceLetterOnly(short)) {
      return short;
    }
    // Intentionally omit [label] — that would select an option for the user.
    return '';
  }
}
