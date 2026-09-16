import 'dart:math';

import 'package:studee_pc/domain/entities/question.dart';

/// Fixed Ôn tập exam size and duration (Giải đề + Giải & luyện).
abstract final class ReviewQuizConfig {
  static const int questionCount = 40;
  static const Duration duration = Duration(minutes: 30);
}

/// Build an Ôn tập set of exactly [size] questions.
///
/// Sorts by [Question.practiceCount] ascending (least practiced first),
/// shuffles within the same count, takes the first [size] unique items, then
/// pads by cycling that ordered list when fewer than [size] exist.
List<Question> buildShuffledQuizSet(
  List<Question> source, {
  int size = ReviewQuizConfig.questionCount,
  Random? random,
}) {
  if (source.isEmpty || size <= 0) return const [];
  final rng = random ?? Random();

  final byCount = <int, List<Question>>{};
  for (final q in source) {
    byCount.putIfAbsent(q.practiceCount, () => []).add(q);
  }
  final counts = byCount.keys.toList()..sort();
  final ordered = <Question>[];
  for (final count in counts) {
    final batch = byCount[count]!..shuffle(rng);
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
