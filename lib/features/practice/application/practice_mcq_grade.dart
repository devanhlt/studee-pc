import 'package:studee_pc/domain/entities/practice_turn.dart';

/// Local MCQ grading + feedback sanitization for practice mode.
class PracticeMcqGrade {
  PracticeMcqGrade._();

  /// Match A/B (or full choice text) against the stored correct label.
  static bool? grade({
    required String answer,
    required String? correctLabel,
    required List<PracticeChoice> choices,
  }) {
    if (correctLabel == null || choices.isEmpty) return null;
    final normalized = answer.trim();
    if (normalized.isEmpty) return null;
    final upper = normalized.toUpperCase();

    bool matchesChoice(PracticeChoice c) {
      final label = c.label.toUpperCase();
      if (upper == label) return true;
      if (upper.startsWith('$label.') || upper.startsWith('$label)')) {
        return true;
      }
      if (upper.startsWith('$label ')) return true;
      final display = c.display.trim();
      final content = c.content.trim();
      if (display.isNotEmpty &&
          (normalized == display ||
              upper == display.toUpperCase() ||
              _similarText(normalized, display))) {
        return true;
      }
      if (content.isNotEmpty &&
          (normalized == content ||
              upper == content.toUpperCase() ||
              _similarText(normalized, content))) {
        return true;
      }
      return false;
    }

    PracticeChoice? correctChoice;
    for (final c in choices) {
      if (c.label.toUpperCase() == correctLabel.toUpperCase()) {
        correctChoice = c;
        break;
      }
    }
    if (correctChoice == null) return null;

    if (matchesChoice(correctChoice)) return true;
    for (final c in choices) {
      if (c.label == correctChoice.label) continue;
      if (matchesChoice(c)) return false;
    }
    if (RegExp(r'^[AB]\b').hasMatch(upper) &&
        !upper.startsWith(correctLabel.toUpperCase())) {
      return false;
    }
    return null;
  }

  /// Keep grade short if it already contains the next MCQ's content.
  static String sanitizeFeedback({
    required String feedback,
    required bool correct,
    String? nextCheck,
    List<PracticeChoice> nextChoices = const [],
  }) {
    final trimmed = feedback.trim();
    final fallback = correct
        ? 'Chính xác!'
        : 'Chưa đúng. Thử lại nhé.';
    if (trimmed.isEmpty) return fallback;

    String fold(String s) => s
        .toLowerCase()
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll('_', '')
        .replaceAll(r'\{', '')
        .replaceAll(r'\}', '')
        .replaceAll(r'\,', '')
        .replaceAll(RegExp(r'\s+'), '');

    final foldedFeedback = fold(trimmed);
    final spoilers = <String>[
      if (nextCheck != null && nextCheck.trim().isNotEmpty) nextCheck.trim(),
      for (final c in nextChoices) ...[
        if (c.content.trim().isNotEmpty) c.content.trim(),
        if (c.display.trim().isNotEmpty) c.display.trim(),
      ],
    ];
    for (final s in spoilers) {
      if (s.length < 4) continue;
      final fs = fold(s);
      if (_similarText(trimmed, s) ||
          trimmed.toLowerCase().contains(s.toLowerCase()) ||
          (fs.length >= 4 && foldedFeedback.contains(fs))) {
        return fallback;
      }
      // e.g. feedback "c3 = c2 = 22" spoils choice "c3 = 22".
      final assign = RegExp(r'c_?(\d+)\s*=\s*(-?\d+)', caseSensitive: false);
      for (final m in assign.allMatches(s)) {
        final n = m.group(1)!;
        final v = m.group(2)!;
        final hasVar = RegExp('c_?$n', caseSensitive: false).hasMatch(trimmed);
        final hasVal = RegExp('(=\\s*)?$v\\b').hasMatch(trimmed);
        if (hasVar && hasVal) return fallback;
      }
    }
    return trimmed;
  }

  static bool _similarText(String a, String b) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[!.…]'), '')
        .trim();
    final na = norm(a);
    final nb = norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;
    return false;
  }
}
