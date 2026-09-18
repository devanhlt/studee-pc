import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/question.dart';

/// Local practice progress for a subject (no LLM).
class SubjectProgressStats extends Equatable {
  const SubjectProgressStats({
    required this.totalQuestions,
    required this.practicedQuestions,
    required this.neverPracticedQuestions,
    required this.weakQuestions,
    required this.totalPracticeAttempts,
    required this.totalIncorrectAttempts,
    this.averageScore,
  });

  final int totalQuestions;
  final int practicedQuestions;
  final int neverPracticedQuestions;
  final int weakQuestions;

  /// Sum of [Question.practiceCount] across practiced items.
  final int totalPracticeAttempts;

  /// Sum of incorrect attempts (capped per question by practice count).
  final int totalIncorrectAttempts;

  /// 0–10 scale from attempt accuracy; null when nothing practiced.
  final double? averageScore;

  double get practiceCoverage =>
      totalQuestions == 0 ? 0 : practicedQuestions / totalQuestions;

  String get practicedLabel => '$practicedQuestions/$totalQuestions';

  String get averageScoreLabel {
    final score = averageScore;
    if (score == null) return '—';
    return score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1);
  }

  @override
  List<Object?> get props => [
        totalQuestions,
        practicedQuestions,
        neverPracticedQuestions,
        weakQuestions,
        totalPracticeAttempts,
        totalIncorrectAttempts,
        averageScore,
      ];
}

/// One question snippet for LLM advice context.
class ProgressWeakSample extends Equatable {
  const ProgressWeakSample({
    required this.stem,
    required this.practiceCount,
    required this.incorrectCount,
  });

  final String stem;
  final int practiceCount;
  final int incorrectCount;

  @override
  List<Object?> get props => [stem, practiceCount, incorrectCount];
}

/// Aggregates practice / incorrect counters into report stats + weak samples.
SubjectProgressStats computeSubjectProgressStats(List<Question> questions) {
  var practiced = 0;
  var never = 0;
  var weak = 0;
  var attempts = 0;
  var incorrect = 0;

  for (final q in questions) {
    if (q.practiceCount <= 0) {
      never++;
      continue;
    }
    practiced++;
    attempts += q.practiceCount;
    final wrong = q.incorrectCount.clamp(0, q.practiceCount);
    incorrect += wrong;
    if (wrong / q.practiceCount >= 0.5) {
      weak++;
    }
  }

  final double? avg = attempts == 0
      ? null
      : ((attempts - incorrect) / attempts) * 10.0;

  return SubjectProgressStats(
    totalQuestions: questions.length,
    practicedQuestions: practiced,
    neverPracticedQuestions: never,
    weakQuestions: weak,
    totalPracticeAttempts: attempts,
    totalIncorrectAttempts: incorrect,
    averageScore: avg,
  );
}

/// Up to [limit] weakest practiced stems (highest incorrect ratio).
List<ProgressWeakSample> collectWeakSamples(
  List<Question> questions, {
  int limit = 8,
  int maxStemChars = 160,
}) {
  final scored = <({Question q, double ratio})>[];
  for (final q in questions) {
    if (q.practiceCount <= 0) continue;
    final wrong = q.incorrectCount.clamp(0, q.practiceCount);
    if (wrong <= 0) continue;
    scored.add((q: q, ratio: wrong / q.practiceCount));
  }
  scored.sort((a, b) {
    final byRatio = b.ratio.compareTo(a.ratio);
    if (byRatio != 0) return byRatio;
    return b.q.incorrectCount.compareTo(a.q.incorrectCount);
  });

  return [
    for (final item in scored.take(limit))
      ProgressWeakSample(
        stem: _truncateStem(item.q.content, maxStemChars),
        practiceCount: item.q.practiceCount,
        incorrectCount: item.q.incorrectCount.clamp(0, item.q.practiceCount),
      ),
  ];
}

String _truncateStem(String raw, int maxChars) {
  final t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= maxChars) return t;
  return '${t.substring(0, maxChars - 1)}…';
}
