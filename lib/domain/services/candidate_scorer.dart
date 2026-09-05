import 'dart:math' as math;

import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

/// Deterministic candidate scoring for retrieval ranking.
///
/// Incorrect evidence is worse than no evidence — scores below [rejectThreshold]
/// are discarded.
class CandidateScorer {
  const CandidateScorer({
    this.rejectThreshold = 0.35,
    this.highLexicalThreshold = 0.85,
  });

  final double rejectThreshold;
  final double highLexicalThreshold;

  static const double _wQuestion = 0.40;
  static const double _wChoiceSet = 0.25;
  static const double _wVerification = 0.15;
  static const double _wSourcePriority = 0.10;
  static const double _wFormula = 0.10;

  /// Score and filter [candidates] against [question].
  List<RankedCandidate> scoreAndFilter({
    required ParsedQuestion question,
    required List<RankedCandidate> candidates,
  }) {
    final scored = <RankedCandidate>[];
    for (final candidate in candidates) {
      if (!candidate.verificationStatus.isRetrievable) continue;
      final result = score(question: question, candidate: candidate);
      if (result.score < rejectThreshold) continue;
      scored.add(result);
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Compute a single candidate score (may be below threshold).
  RankedCandidate score({
    required ParsedQuestion question,
    required RankedCandidate candidate,
  }) {
    final qNorm = TextNormalizer.normalizeQuestionText(question.content);
    final cNorm = TextNormalizer.normalizeQuestionText(
      candidate.normalizedContent ?? candidate.content,
    );

    final questionSim = _tokenDice(qNorm, cNorm);
    final choiceSim = _choiceSetSimilarity(question, candidate);
    final verificationWeight =
        _verificationWeight(candidate.verificationStatus);
    final priorityWeight = _sourcePriorityWeight(candidate.sourcePriority);
    final formulaOverlap = _formulaOverlap(qNorm, cNorm);

    final total = (_wQuestion * questionSim) +
        (_wChoiceSet * choiceSim) +
        (_wVerification * verificationWeight) +
        (_wSourcePriority * priorityWeight) +
        (_wFormula * formulaOverlap);

    final currentFp = Fingerprints.questionFingerprint(
      questionText: question.content,
      choiceContents: question.choiceContents,
    );
    final candidateFp = candidate.questionId != null
        ? Fingerprints.questionFingerprint(
            questionText: candidate.content,
            choiceContents: candidate.choices.map((c) => c.content),
          )
        : null;

    final exact = candidateFp != null && candidateFp == currentFp;
    final numericSim = _numericSignatureSimilarity(qNorm, cNorm);

    // High-lexical = same question despite OCR/choice drift — NOT a sibling
    // problem that shares wording but changes numbers / matrices.
    final highLexical = exact ||
        (questionSim >= highLexicalThreshold &&
            choiceSim >= 0.55 &&
            numericSim >= 0.85) ||
        (questionSim >= 0.94 && choiceSim >= 0.4 && numericSim >= 0.9) ||
        (questionSim >= 0.97 && numericSim >= 0.95);

    return candidate.copyWith(
      score: double.parse(total.toStringAsFixed(6)),
      exactFingerprintMatch: exact,
      highLexicalMatch: highLexical || exact,
    );
  }

  /// Compare digit sequences so "2A+3B with matrix X" ≠ "2A+3B with matrix Y".
  double _numericSignatureSimilarity(String a, String b) {
    final na = _numberTokens(a);
    final nb = _numberTokens(b);
    if (na.isEmpty && nb.isEmpty) return 1.0;
    if (na.isEmpty || nb.isEmpty) return 0.55;
    if (na.length != nb.length) {
      // Different count of numbers usually means a different exercise.
      final shorter = math.min(na.length, nb.length);
      final longer = math.max(na.length, nb.length);
      if (shorter == 0) return 0.0;
      var matched = 0;
      final used = List<bool>.filled(nb.length, false);
      for (final x in na) {
        for (var i = 0; i < nb.length; i++) {
          if (used[i]) continue;
          if (nb[i] == x) {
            used[i] = true;
            matched++;
            break;
          }
        }
      }
      return matched / longer;
    }
    var matched = 0;
    for (var i = 0; i < na.length; i++) {
      if (na[i] == nb[i]) matched++;
    }
    // Also credit multiset overlap when order drifts (OCR).
    final multiset =
        (matched / na.length + _multisetOverlap(na, nb)) / 2.0;
    return multiset;
  }

  double _multisetOverlap(List<String> a, List<String> b) {
    final counts = <String, int>{};
    for (final x in a) {
      counts[x] = (counts[x] ?? 0) + 1;
    }
    var inter = 0;
    for (final y in b) {
      final c = counts[y] ?? 0;
      if (c > 0) {
        inter++;
        counts[y] = c - 1;
      }
    }
    return (2.0 * inter) / (a.length + b.length);
  }

  List<String> _numberTokens(String text) {
    return RegExp(r'-?\d+(?:[.,]\d+)?')
        .allMatches(text)
        .map((m) => m.group(0)!.replaceAll(',', '.'))
        .toList();
  }

  double _choiceSetSimilarity(
    ParsedQuestion question,
    RankedCandidate candidate,
  ) {
    if (question.choices.isEmpty && candidate.choices.isEmpty) {
      return 1.0; // both text-response style
    }
    if (question.choices.isEmpty || candidate.choices.isEmpty) {
      return 0.0;
    }

    final currentFp = Fingerprints.choiceSetFingerprint(question.choiceContents);
    final storedFp = candidate.choiceSetFingerprint ??
        Fingerprints.choiceSetFingerprint(
          candidate.choices.map((c) => c.content),
        );
    if (currentFp == storedFp) return 1.0;

    final a = question.choiceContents
        .map(TextNormalizer.normalizeChoiceContent)
        .where((s) => s.isNotEmpty)
        .toSet();
    final b = candidate.choices
        .map((c) => TextNormalizer.normalizeChoiceContent(c.content))
        .where((s) => s.isNotEmpty)
        .toSet();
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  double _verificationWeight(VerificationStatus status) => switch (status) {
        VerificationStatus.official => 1.0,
        VerificationStatus.reviewed => 0.85,
        VerificationStatus.unreviewed => 0.35,
        VerificationStatus.inferred => 0.2,
        VerificationStatus.conflicted => 0.1,
        VerificationStatus.rejected => 0.0,
      };

  double _sourcePriorityWeight(int priority) {
    // priority typically 0..100; clamp into 0..1
    return (priority.clamp(0, 100)) / 100.0;
  }

  double _formulaOverlap(String a, String b) {
    final formulasA = _extractFormulas(a);
    final formulasB = _extractFormulas(b);
    if (formulasA.isEmpty && formulasB.isEmpty) return 0.5;
    if (formulasA.isEmpty || formulasB.isEmpty) return 0.0;
    final inter = formulasA.intersection(formulasB).length;
    final union = formulasA.union(formulasB).length;
    return union == 0 ? 0.0 : inter / union;
  }

  Set<String> _extractFormulas(String text) {
    final latex = RegExp(r'\$[^$]+\$|\\\([^)]+\\\)|\\\[[^\]]+\\\]');
    final matches = latex.allMatches(text).map((m) => m.group(0)!).toSet();
    // Also catch simple identifier-like math tokens (det, sin, etc.)
    final tokens = RegExp(r'[A-Za-z\\]+\([^)]*\)')
        .allMatches(text)
        .map((m) => m.group(0)!.toLowerCase());
    return {...matches, ...tokens};
  }

  double _tokenDice(String a, String b) {
    final ta = _tokens(a);
    final tb = _tokens(b);
    if (ta.isEmpty && tb.isEmpty) return 1.0;
    if (ta.isEmpty || tb.isEmpty) return 0.0;
    final inter = ta.intersection(tb).length;
    return (2.0 * inter) / (ta.length + tb.length);
  }

  Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^0-9a-zA-Zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩị'
            r'òóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+'))
        .where((t) => t.length >= 2)
        .toSet();
  }

  /// Accent-folded similarity for lower-ranked fallback only.
  double accentFoldedSimilarity(String a, String b) {
    return _tokenDice(
      TextNormalizer.accentFolded(a),
      TextNormalizer.accentFolded(b),
    );
  }

  /// Softmax-free relative rank helper (deterministic).
  static List<double> normalizeScores(List<double> scores) {
    if (scores.isEmpty) return const [];
    final max = scores.reduce(math.max);
    if (max <= 0) return List.filled(scores.length, 0);
    return scores.map((s) => s / max).toList();
  }
}
