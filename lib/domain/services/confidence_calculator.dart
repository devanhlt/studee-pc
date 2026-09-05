import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/confidence_level.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';

/// Computes application confidence from evidence — never from model self-report.
class ConfidenceCalculator {
  const ConfidenceCalculator();

  ConfidenceLevel calculate({
    required PrecedenceDecision decision,
    required List<RankedCandidate> evidenceCandidates,
  }) {
    return switch (decision) {
      TrustedConflictDecision() => ConfidenceLevel.conflict,
      FixedOfficialDecision() => ConfidenceLevel.high,
      PreferStoredReviewedDecision(:final candidate) =>
        candidate.exactFingerprintMatch || candidate.highLexicalMatch
            ? ConfidenceLevel.high
            : ConfidenceLevel.medium,
      CommonTrustedDecision(:final candidates) =>
        candidates.any((c) => c.exactFingerprintMatch || c.highLexicalMatch)
            ? ConfidenceLevel.high
            : ConfidenceLevel.medium,
      SoftMatchContextDecision() => ConfidenceLevel.medium,
      UnreviewedContextDecision() => ConfidenceLevel.low,
      ModelKnowledgeDecision() => ConfidenceLevel.low,
    };
  }

  /// Alternate entry when precedence was not run but evidence is available.
  ConfidenceLevel fromEvidence({
    required List<RankedCandidate> candidates,
    required bool trustedConflict,
    required bool modelKnowledgeUsed,
  }) {
    if (trustedConflict) return ConfidenceLevel.conflict;

    final trusted = candidates
        .where((c) => c.verificationStatus.isTrusted && c.hasAnswer)
        .toList();

    if (trusted.any(
      (c) => c.exactFingerprintMatch || c.highLexicalMatch,
    )) {
      return ConfidenceLevel.high;
    }

    if (trusted.length >= 2) {
      return ConfidenceLevel.medium;
    }

    const theoryTypes = {
      KnowledgeUnitType.theory,
      KnowledgeUnitType.formula,
      KnowledgeUnitType.theorem,
      KnowledgeUnitType.definition,
    };
    final strongTheory = candidates.any(
      (c) =>
          c.verificationStatus.isTrusted &&
          c.score >= 0.6 &&
          c.unitType != null &&
          theoryTypes.contains(c.unitType),
    );
    if (strongTheory) return ConfidenceLevel.medium;

    if (modelKnowledgeUsed || candidates.isEmpty) {
      return ConfidenceLevel.low;
    }

    final onlyUnreviewed = candidates.every(
      (c) =>
          c.verificationStatus == VerificationStatus.unreviewed ||
          c.verificationStatus == VerificationStatus.inferred,
    );
    if (onlyUnreviewed) return ConfidenceLevel.low;

    return ConfidenceLevel.low;
  }
}
