import 'package:equatable/equatable.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';

/// Implements the product answer-precedence policy.
///
/// Imported **question + answer** pairs are locked only when a strong match
/// has a unique stored answer. Same stem/fingerprint with different answers
/// → conflict (all pairs go to the LLM; never PreferStored one side).
/// Pure knowledge units never lock an answer.
class AnswerPrecedence {
  const AnswerPrecedence({
    this.choiceMapper = const ChoiceMapper(),
  });

  final ChoiceMapper choiceMapper;

  /// Evaluate candidates and produce a precedence decision.
  PrecedenceDecision resolve({
    required ParsedQuestion currentQuestion,
    required List<RankedCandidate> candidates,
  }) {
    final usable = candidates
        .where(
          (c) =>
              c.verificationStatus.isRetrievable &&
              c.hasAnswer &&
              _isQuestionPair(c),
        )
        .toList();

    if (usable.isEmpty) {
      final contextOnly = candidates
          .where((c) => c.verificationStatus.isRetrievable)
          .toList();
      if (contextOnly.isNotEmpty) {
        return SoftMatchContextDecision(
          contextCandidates: contextOnly,
          warning:
              'Có kiến thức gần giống nhưng chưa đủ khớp để khóa đáp án. '
              'AI giải kèm ngữ cảnh.',
        );
      }
      return const ModelKnowledgeDecision(
        disclosure:
            'Không có bằng chứng phù hợp trong môn học. Đáp án dựa trên '
            'kiến thức mô hình và được công bố rõ.',
      );
    }

    bool strong(RankedCandidate c) =>
        c.exactFingerprintMatch || c.highLexicalMatch;

    final strongPairs = usable.where(strong).toList();

    // Same matched question, different imported answers → do not lock.
    if (strongPairs.length >= 2 && !_uniqueRawAnswer(strongPairs)) {
      final rawGroups = <String, List<RankedCandidate>>{};
      for (final candidate in strongPairs) {
        rawGroups
            .putIfAbsent(answerCompareKey(candidate), () => [])
            .add(candidate);
      }
      return TrustedConflictDecision(
        conflicting: rawGroups.entries
            .map(
              (e) => ConflictingAnswerGroup(
                answerKey: e.key,
                candidates: e.value,
              ),
            )
            .toList(),
        warning:
            'Cùng câu hỏi nhưng đáp án đã nhập khác nhau. '
            'Không khóa một đáp án — AI đối chiếu các cặp câu hỏi–đáp án.',
      );
    }

    final exactOfficial = usable.where(
      (c) =>
          strong(c) &&
          c.exactFingerprintMatch &&
          c.verificationStatus == VerificationStatus.official,
    );
    if (exactOfficial.isNotEmpty && _uniqueRawAnswer(strongPairs)) {
      final mapped = _mapFirst(currentQuestion, exactOfficial);
      if (mapped != null) {
        return FixedOfficialDecision(
          candidate: exactOfficial.first,
          mapped: mapped,
          constraint: AnswerConstraint(
            fixed: true,
            answerLabel: mapped.label,
            answerContent: mapped.content,
          ),
        );
      }
    }

    final strongTrusted = usable
        .where((c) => c.verificationStatus.isTrusted && strong(c))
        .toList();
    if (strongTrusted.length >= 2 && _uniqueRawAnswer(strongTrusted)) {
      final representative = strongTrusted.first;
      final mapped = choiceMapper.mapStoredAnswer(
        storedAnswerContent: representative.answerContent,
        storedAnswerLabel: representative.answerLabel,
        currentQuestion: currentQuestion,
      );
      if (mapped != null) {
        return CommonTrustedDecision(
          candidates: strongTrusted,
          mapped: mapped,
          constraint: AnswerConstraint(
            fixed: true,
            answerLabel: mapped.label,
            answerContent: mapped.content,
          ),
        );
      }
    }

    if (strongPairs.length == 1 || _uniqueRawAnswer(strongPairs)) {
      final exactOrHighReviewed = usable.where(
        (c) =>
            strong(c) &&
            (c.verificationStatus == VerificationStatus.reviewed ||
                c.verificationStatus == VerificationStatus.official),
      );
      if (exactOrHighReviewed.isNotEmpty) {
        final mapped = _mapFirst(currentQuestion, exactOrHighReviewed);
        if (mapped != null) {
          final c = exactOrHighReviewed.first;
          if (c.verificationStatus == VerificationStatus.official &&
              c.exactFingerprintMatch) {
            return FixedOfficialDecision(
              candidate: c,
              mapped: mapped,
              constraint: AnswerConstraint(
                fixed: true,
                answerLabel: mapped.label,
                answerContent: mapped.content,
              ),
            );
          }
          return PreferStoredReviewedDecision(
            candidate: c,
            mapped: mapped,
            constraint: AnswerConstraint(
              fixed: true,
              answerLabel: mapped.label,
              answerContent: mapped.content,
            ),
          );
        }
      }

      final strongImported = usable.where(
        (c) =>
            strong(c) &&
            (c.verificationStatus == VerificationStatus.unreviewed ||
                c.verificationStatus == VerificationStatus.inferred),
      );
      if (strongImported.isNotEmpty) {
        final mapped = _mapFirst(currentQuestion, strongImported);
        if (mapped != null) {
          return PreferStoredReviewedDecision(
            candidate: strongImported.first,
            mapped: mapped,
            constraint: AnswerConstraint(
              fixed: true,
              answerLabel: mapped.label,
              answerContent: mapped.content,
            ),
          );
        }
      }
    }

    return SoftMatchContextDecision(
      contextCandidates: usable.isNotEmpty ? usable : candidates,
      warning:
          'Câu hỏi gần giống kiến thức đã nhập nhưng chưa đủ khớp để khóa '
          'đáp án. AI giải dựa trên ngữ cảnh (có thể khác đáp án đã lưu).',
    );
  }

  /// Question rows (and legacy null-typed answer rows) — not pure knowledge.
  static bool _isQuestionPair(RankedCandidate c) {
    if (c.questionId != null) return true;
    final type = c.unitType;
    if (type == null) return true;
    return type == KnowledgeUnitType.question;
  }

  MappedAnswer? _mapFirst(
    ParsedQuestion question,
    Iterable<RankedCandidate> candidates,
  ) {
    for (final candidate in candidates) {
      final mapped = choiceMapper.mapStoredAnswer(
        storedAnswerContent: candidate.answerContent,
        storedAnswerLabel: candidate.answerLabel,
        currentQuestion: question,
      );
      if (mapped != null) return mapped;
    }
    return null;
  }

  static bool _uniqueRawAnswer(List<RankedCandidate> candidates) {
    if (candidates.isEmpty) return false;
    return candidates.map(answerCompareKey).toSet().length == 1;
  }

  /// Compare stored answers by content only (ignore A/B/C letter prefixes).
  ///
  /// Different imported labels with the same body are treated as agreement;
  /// choice remapping happens later via [ChoiceMapper].
  static String answerCompareKey(RankedCandidate c) {
    final content =
        TextNormalizer.normalizeAnswerForCompare(c.answerContent ?? '');
    if (content.isNotEmpty && !TextNormalizer.isBareChoiceLabel(content)) {
      return content;
    }
    // Label-only / bare-letter answers: last resort (no body to compare).
    final label = (c.answerLabel ?? '').trim().toLowerCase();
    if (label.isNotEmpty) return 'label:$label';
    return content;
  }

  /// Dedupe key for evidence packing: same stem + same answer body → one item.
  static String evidenceDedupeKey(RankedCandidate c) {
    final stem =
        TextNormalizer.normalizeQuestionText(c.content).toLowerCase();
    return '$stem||${answerCompareKey(c)}';
  }
}

/// Outcome of [AnswerPrecedence.resolve].
sealed class PrecedenceDecision extends Equatable {
  const PrecedenceDecision();

  AnswerConstraint get constraint;
  List<String> get warnings;
  bool get modelKnowledgeDisclosure;
}

/// Exact official match — code fixes answer; AI explains.
final class FixedOfficialDecision extends PrecedenceDecision {
  const FixedOfficialDecision({
    required this.candidate,
    required this.mapped,
    required this.constraint,
  });

  final RankedCandidate candidate;
  final MappedAnswer mapped;

  @override
  final AnswerConstraint constraint;

  @override
  List<String> get warnings => const [];

  @override
  bool get modelKnowledgeDisclosure => false;

  @override
  List<Object?> get props => [candidate, mapped, constraint];
}

/// Exact/high reviewed match — prefer stored answer.
final class PreferStoredReviewedDecision extends PrecedenceDecision {
  const PreferStoredReviewedDecision({
    required this.candidate,
    required this.mapped,
    required this.constraint,
  });

  final RankedCandidate candidate;
  final MappedAnswer mapped;

  @override
  final AnswerConstraint constraint;

  @override
  List<String> get warnings => const [];

  @override
  bool get modelKnowledgeDisclosure => false;

  @override
  List<Object?> get props => [candidate, mapped, constraint];
}

/// Multiple trusted sources agree on the same mapped answer.
final class CommonTrustedDecision extends PrecedenceDecision {
  const CommonTrustedDecision({
    required this.candidates,
    required this.mapped,
    required this.constraint,
  });

  final List<RankedCandidate> candidates;
  final MappedAnswer mapped;

  @override
  final AnswerConstraint constraint;

  @override
  List<String> get warnings => const [];

  @override
  bool get modelKnowledgeDisclosure => false;

  @override
  List<Object?> get props => [candidates, mapped, constraint];
}

/// Trusted sources disagree — no automatic choice; LLM sees all Q+A pairs.
final class TrustedConflictDecision extends PrecedenceDecision {
  const TrustedConflictDecision({
    required this.conflicting,
    required this.warning,
  });

  final List<ConflictingAnswerGroup> conflicting;
  final String warning;

  @override
  AnswerConstraint get constraint => AnswerConstraint.none;

  @override
  List<String> get warnings => [warning];

  @override
  bool get modelKnowledgeDisclosure => false;

  /// All conflicting question+answer candidates for evidence.
  List<RankedCandidate> get allCandidates =>
      conflicting.expand((g) => g.candidates).toList();

  @override
  List<Object?> get props => [conflicting, warning];
}

/// Only unreviewed / inferred evidence — context with warning.
final class UnreviewedContextDecision extends PrecedenceDecision {
  const UnreviewedContextDecision({
    required this.contextCandidates,
    required this.warning,
  });

  final List<RankedCandidate> contextCandidates;
  final String warning;

  @override
  AnswerConstraint get constraint => AnswerConstraint.none;

  @override
  List<String> get warnings => [warning];

  @override
  bool get modelKnowledgeDisclosure => false;

  @override
  List<Object?> get props => [contextCandidates, warning];
}

/// Near-match evidence (soft lexical / FTS) — usable as context, not fixed answer.
final class SoftMatchContextDecision extends PrecedenceDecision {
  const SoftMatchContextDecision({
    required this.contextCandidates,
    required this.warning,
  });

  final List<RankedCandidate> contextCandidates;
  final String warning;

  @override
  AnswerConstraint get constraint => AnswerConstraint.none;

  @override
  List<String> get warnings => [warning];

  @override
  bool get modelKnowledgeDisclosure => false;

  @override
  List<Object?> get props => [contextCandidates, warning];
}

/// No relevant evidence — model knowledge with disclosure.
final class ModelKnowledgeDecision extends PrecedenceDecision {
  const ModelKnowledgeDecision({required this.disclosure});

  final String disclosure;

  @override
  AnswerConstraint get constraint => AnswerConstraint.none;

  @override
  List<String> get warnings => [disclosure];

  @override
  bool get modelKnowledgeDisclosure => true;

  @override
  List<Object?> get props => [disclosure];
}

class ConflictingAnswerGroup extends Equatable {
  const ConflictingAnswerGroup({
    required this.answerKey,
    required this.candidates,
  });

  final String answerKey;
  final List<RankedCandidate> candidates;

  @override
  List<Object?> get props => [answerKey, candidates];
}
