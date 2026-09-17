import 'dart:math';

import 'package:studee_pc/domain/entities/question.dart';

/// Fixed Ôn tập exam size and duration (Giải đề + Giải & luyện).
abstract final class ReviewQuizConfig {
  static const int questionCount = 40;
  static const Duration duration = Duration(minutes: 30);
}

/// Build an Ôn tập set of exactly [size] questions.
///
/// Priority order:
/// 1. Higher [Question.incorrectCount] first (often missed)
/// 2. Lower [Question.practiceCount] next (little practice)
/// Shuffles within the same (incorrect, practice) pair, takes the first
/// [size] unique items, then pads by cycling that ordered list when fewer
/// than [size] exist.
List<Question> buildShuffledQuizSet(
  List<Question> source, {
  int size = ReviewQuizConfig.questionCount,
  Random? random,
}) {
  if (source.isEmpty || size <= 0) return const [];
  final rng = random ?? Random();

  final byKey = <(int, int), List<Question>>{};
  for (final q in source) {
    byKey.putIfAbsent((q.incorrectCount, q.practiceCount), () => []).add(q);
  }
  final keys = byKey.keys.toList()
    ..sort((a, b) {
      // More incorrect first.
      final incorrectCmp = b.$1.compareTo(a.$1);
      if (incorrectCmp != 0) return incorrectCmp;
      // Then less practiced first.
      return a.$2.compareTo(b.$2);
    });

  final ordered = <Question>[];
  for (final key in keys) {
    final batch = byKey[key]!..shuffle(rng);
    ordered.addAll(batch);
  }

  final out = <Question>[];
  for (final q in ordered) {
    if (out.length >= size) break;
    out.add(q);
  }
  var i = 0;
  while (out.length < size) {
    out.add(ordered[i % ordered.length]);
    i++;
  }
  return out;
}

String formatQuizCountdown(Duration remaining) {
  final totalSeconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
