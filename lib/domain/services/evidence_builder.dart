import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/evidence_item.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';

/// Builds a token-limited evidence package (3–8 units) for DeepSeek.
///
/// - **Question + answer** pairs are always emitted together (stem, choices,
///   stored answer, explanation).
/// - **Pure knowledge** (theory / definition / formula / …) is content only.
class EvidenceBuilder {
  const EvidenceBuilder({
    this.minUnits = 3,
    this.maxUnits = 8,
    this.maxTokens = 3500,
  });

  final int minUnits;
  final int maxUnits;
  final int maxTokens;

  /// Approximate chars-per-token for mixed Vietnamese/English study text.
  static const double charsPerToken = 3.5;

  EvidencePackage build({
    required ParsedQuestion currentQuestion,
    required List<RankedCandidate> rankedCandidates,
    required PrecedenceDecision decision,
    AnswerConstraint? overrideConstraint,
  }) {
    final constraint = overrideConstraint ?? decision.constraint;
    final warnings = <String>[...decision.warnings];

    // Prefer full Q+A pairs first, then pure knowledge; skip orphan answer_key
    // / solution units when a parent question pair is already present.
    final ordered = _dedupeAgreeingQaPairs(
      _prioritizeCandidates(rankedCandidates, decision),
    );

    final selected = <RankedCandidate>[];
    var tokens = _estimateQuestionTokens(currentQuestion);

    for (final candidate in ordered) {
      if (selected.length >= maxUnits) break;
      final body = _evidenceContent(candidate);
      final itemTokens = _estimateTokens(body);
      if (selected.length >= minUnits && tokens + itemTokens > maxTokens) {
        break;
      }
      selected.add(candidate);
      tokens += itemTokens;
    }

    if (selected.isEmpty && ordered.isNotEmpty) {
      selected.add(ordered.first);
      tokens += _estimateTokens(_evidenceContent(ordered.first));
      warnings.add(
        'Gói bằng chứng bị cắt ngắn do giới hạn token.',
      );
    }

    if (tokens > maxTokens) {
      warnings.add(
        'Gói bằng chứng vượt ngân sách token ước tính; nội dung đã được giới hạn.',
      );
    }

    final evidence = <EvidenceItem>[];
    for (var i = 0; i < selected.length; i++) {
      final c = selected[i];
      evidence.add(
        EvidenceItem(
          evidenceId: 'ev_${(i + 1).toString().padLeft(3, '0')}',
          localId: c.localId,
          type: c.unitType ??
              (c.questionId != null
                  ? KnowledgeUnitType.question
                  : KnowledgeUnitType.note),
          content: _truncateToBudget(
            _evidenceContent(c),
            remaining: maxTokens - _estimateQuestionTokens(currentQuestion),
            alreadyUsed: evidence.fold<int>(
              0,
              (sum, e) => sum + _estimateTokens(e.content),
            ),
          ),
          verificationStatus: c.verificationStatus,
          sourceTitle: c.sourceTitle,
          page: c.page,
        ),
      );
    }

    return EvidencePackage(
      currentQuestion: currentQuestion,
      answerConstraint: constraint,
      evidence: evidence,
      warnings: warnings,
      estimatedTokens: tokens,
    );
  }

  List<RankedCandidate> _prioritizeCandidates(
    List<RankedCandidate> ranked,
    PrecedenceDecision decision,
  ) {
    final preferredIds = <String>{};
    if (decision is TrustedConflictDecision) {
      preferredIds.addAll(decision.allCandidates.map((c) => c.localId));
    } else if (decision is PreferStoredReviewedDecision) {
      preferredIds.add(decision.candidate.localId);
    } else if (decision is FixedOfficialDecision) {
      preferredIds.add(decision.candidate.localId);
    } else if (decision is CommonTrustedDecision) {
      preferredIds.addAll(decision.candidates.map((c) => c.localId));
    }

    final hasQuestionPair = ranked.any(_isQuestionPair);

    final filtered = ranked.where((c) {
      if (_isAnswerOrSolution(c) && hasQuestionPair) return false;
      return true;
    }).toList();

    int rank(RankedCandidate c) {
      if (preferredIds.contains(c.localId)) return 0;
      if (_isQuestionPair(c) && c.hasAnswer) return 1;
      if (_isQuestionPair(c)) return 2;
      if (_isPureKnowledge(c)) return 3;
      return 4;
    }

    filtered.sort((a, b) {
      final rd = rank(a).compareTo(rank(b));
      if (rd != 0) return rd;
      return b.score.compareTo(a.score);
    });
    return filtered;
  }

  /// Drop duplicate Q+A pairs that only differ by A/B/C label (same stem+body).
  List<RankedCandidate> _dedupeAgreeingQaPairs(List<RankedCandidate> ordered) {
    final seen = <String>{};
    final out = <RankedCandidate>[];
    for (final c in ordered) {
      if (_isQuestionPair(c) && c.hasAnswer) {
        final key = AnswerPrecedence.evidenceDedupeKey(c);
        if (key.isNotEmpty && !seen.add(key)) {
          continue;
        }
      }
      out.add(c);
    }
    return out;
  }

  static bool _isQuestionPair(RankedCandidate c) {
    if (c.questionId != null) return true;
    return c.unitType == KnowledgeUnitType.question;
  }

  static bool _isPureKnowledge(RankedCandidate c) {
    final t = c.unitType;
    if (t == null) return false;
    return t == KnowledgeUnitType.theory ||
        t == KnowledgeUnitType.definition ||
        t == KnowledgeUnitType.formula ||
        t == KnowledgeUnitType.theorem ||
        t == KnowledgeUnitType.example ||
        t == KnowledgeUnitType.table ||
        t == KnowledgeUnitType.note;
  }

  static bool _isAnswerOrSolution(RankedCandidate c) {
    final t = c.unitType;
    return t == KnowledgeUnitType.answerKey || t == KnowledgeUnitType.solution;
  }

  /// Question+answer → full pair. Pure knowledge → content only.
  String _evidenceContent(RankedCandidate c) {
    if (_isQuestionPair(c)) {
      final buffer = StringBuffer();
      buffer.writeln('--- Cặp câu hỏi & đáp án đã nhập ---');
      buffer.writeln('Câu hỏi:');
      buffer.writeln(c.content);
      if (c.choices.isNotEmpty) {
        buffer.writeln('Lựa chọn:');
        for (final choice in c.choices) {
          buffer.writeln('${choice.label}. ${choice.content}');
        }
      }
      if (c.hasAnswer) {
        final body = (c.answerContent ?? '').trim();
        final label = (c.answerLabel ?? '').trim();
        if (body.isNotEmpty) {
          buffer.writeln(
            'Đáp án đi kèm (theo nội dung — khớp theo nội dung, '
            'không phụ thuộc chữ cái A/B/C trong nguồn):',
          );
          buffer.writeln(TextNormalizer.stripChoicePrefix(body));
          if (label.isNotEmpty) {
            buffer.writeln(
              'Nhãn gốc trong nguồn: $label '
              '(chỉ tham chiếu; bộ lựa chọn có thể đã bị đảo thứ tự).',
            );
          }
        } else if (label.isNotEmpty) {
          buffer.writeln('Đáp án đi kèm (chỉ có nhãn): $label');
        } else {
          buffer.writeln('Đáp án đi kèm: (không có)');
        }
      } else {
        buffer.writeln('Đáp án đi kèm: (không có)');
      }
      final explanation = c.explanation?.trim();
      if (explanation != null && explanation.isNotEmpty) {
        buffer.writeln('Giải thích đi kèm:');
        buffer.writeln(explanation);
      }
      return buffer.toString().trim();
    }

    // Pure knowledge / orphan answer units: content only.
    final buffer = StringBuffer();
    final typeLabel = c.unitType?.labelVi;
    if (typeLabel != null) {
      buffer.writeln('Kiến thức ($typeLabel):');
    }
    buffer.write(c.content.trim());
    return buffer.toString().trim();
  }

  int _estimateQuestionTokens(ParsedQuestion question) {
    var total = _estimateTokens(question.content);
    for (final choice in question.choices) {
      total += _estimateTokens('${choice.label}. ${choice.content}');
    }
    return total;
  }

  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / charsPerToken).ceil();
  }

  String _truncateToBudget(
    String content, {
    required int remaining,
    required int alreadyUsed,
  }) {
    final available = remaining - alreadyUsed;
    if (available <= 0) return content;
    final maxChars = (available * charsPerToken).floor();
    if (content.length <= maxChars) return content;
    if (maxChars <= 3) return '...';
    return '${content.substring(0, maxChars - 3)}...';
  }
}
