import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';

/// Validates DeepSeek grounded-answer JSON against the request evidence package.
///
/// Checks:
/// - every `used_evidence_ids` entry was in the request (unknown ids stripped);
/// - MC label exists among current choices (or remapped from content);
/// - label/content drift is **coerced** when possible (prefix / paraphrase);
/// - fixed [AnswerConstraint] is enforced by coercing the response (not rejecting).
class ResponseValidator {
  const ResponseValidator();

  Result<DeepSeekAnswerResponse> validate({
    required DeepSeekAnswerResponse response,
    required EvidencePackage package,
  }) {
    final warnings = <String>[...response.warnings];

    final allowedIds = package.evidence.map((e) => e.evidenceId).toSet();
    final cleanedEvidenceIds = <String>[];
    for (final id in response.usedEvidenceIds) {
      if (allowedIds.contains(id)) {
        cleanedEvidenceIds.add(id);
      } else {
        warnings.add('Bỏ evidence id không hợp lệ: $id');
      }
    }

    final constraint = package.answerConstraint;
    final choices = package.currentQuestion.choices;

    // When application code already fixed the answer from imported knowledge,
    // never hard-fail on label/content drift — coerce and keep the explanation.
    if (constraint.fixed) {
      return Success(
        DeepSeekAnswerResponse(
          questionType: response.questionType,
          finalAnswerLabel:
              constraint.answerLabel ?? response.finalAnswerLabel,
          finalAnswerContent:
              constraint.answerContent ?? response.finalAnswerContent,
          shortAnswer: constraint.answerLabel ??
              response.shortAnswer ??
              constraint.answerContent,
          explanationMarkdown: response.explanationMarkdown,
          usedEvidenceIds: cleanedEvidenceIds.isNotEmpty
              ? cleanedEvidenceIds
              : allowedIds.take(3).toList(),
          modelKnowledgeUsed: false,
          missingInformation: response.missingInformation,
          warnings: warnings,
          rawJson: response.rawJson,
        ),
      );
    }

    var label = response.finalAnswerLabel;
    var content = response.finalAnswerContent;
    final errors = <String>[];

    // Only enforce MC label rules when the live question actually has choices.
    // Free-text / equation questions often get mis-typed as MC by the model.
    if (choices.isNotEmpty) {
      final coerced = _coerceMcAnswer(
        label: label,
        content: content,
        choices: choices,
        warnings: warnings,
      );
      if (coerced == null) {
        if (label == null || label.trim().isEmpty) {
          errors.add('missing_mc_label');
        } else {
          errors.add('mc_label_not_found:$label');
        }
      } else {
        label = coerced.label;
        content = coerced.content;
      }
    }

    if (errors.isNotEmpty) {
      return Failure(
        ValidationFailure(
          userMessage:
              'Phản hồi của Trợ lý Stud không hợp lệ so với gói bằng chứng.',
          code: 'deepseek_response_invalid',
          details: errors.join(','),
        ),
      );
    }

    return Success(
      DeepSeekAnswerResponse(
        questionType: response.questionType,
        finalAnswerLabel: label,
        finalAnswerContent: content,
        shortAnswer: response.shortAnswer ?? label,
        explanationMarkdown: response.explanationMarkdown,
        usedEvidenceIds: cleanedEvidenceIds,
        modelKnowledgeUsed: response.modelKnowledgeUsed,
        missingInformation: response.missingInformation,
        warnings: warnings,
        rawJson: response.rawJson,
      ),
    );
  }

  /// Returns machine-readable validation error codes (empty if valid / coercible).
  List<String> collectErrors({
    required DeepSeekAnswerResponse response,
    required EvidencePackage package,
  }) {
    if (package.answerConstraint.fixed) return const [];

    final choices = package.currentQuestion.choices;
    if (choices.isEmpty) return const [];

    final coerced = _coerceMcAnswer(
      label: response.finalAnswerLabel,
      content: response.finalAnswerContent,
      choices: choices,
      warnings: [],
    );
    if (coerced != null) return const [];

    final label = response.finalAnswerLabel;
    if (label == null || label.trim().isEmpty) {
      return const ['missing_mc_label'];
    }
    return ['mc_label_not_found:$label'];
  }

  /// Align label + content with the live choice list.
  ///
  /// Prefer matching by **content** (ignore A./B) prefixes). If only the label
  /// is valid, force content to that choice body so minor LLM drift never
  /// blocks model-knowledge / low-evidence answers.
  static ({String label, String content})? _coerceMcAnswer({
    required String? label,
    required String? content,
    required List<ParsedChoice> choices,
    required List<String> warnings,
  }) {
    final trimmedContent = content?.trim();
    final hasContent =
        trimmedContent != null && trimmedContent.isNotEmpty;

    // 1) Content wins — remap to the choice whose body matches.
    if (hasContent) {
      final byContent = _findChoiceByContent(choices, trimmedContent);
      if (byContent != null) {
        if (label != null &&
            label.trim().isNotEmpty &&
            label.trim() != byContent.label) {
          warnings.add(
            'Đã khớp đáp án theo nội dung (nhãn Trợ lý Stud "${label.trim()}" '
            '→ "${byContent.label}").',
          );
        }
        return (label: byContent.label, content: byContent.content);
      }
    }

    // 2) Valid label — accept even if content paraphrased / prefixed.
    if (label != null && label.trim().isNotEmpty) {
      final byLabel = _findChoice(choices, label);
      if (byLabel != null) {
        if (hasContent && !_sameContent(trimmedContent, byLabel.content)) {
          warnings.add(
            'Đã chỉnh nội dung đáp án cho khớp lựa chọn ${byLabel.label}.',
          );
        }
        return (label: byLabel.label, content: byLabel.content);
      }
    }

    return null;
  }

  static ParsedChoice? _findChoice(List<ParsedChoice> choices, String label) {
    final needle = label.trim().toUpperCase();
    for (final c in choices) {
      if (c.label.trim().toUpperCase() == needle) return c;
    }
    // Also accept "A." / "A)" as label.
    final stripped = needle.replaceFirst(RegExp(r'[.\)\-–:：]+$'), '');
    if (stripped != needle) {
      for (final c in choices) {
        if (c.label.trim().toUpperCase() == stripped) return c;
      }
    }
    return null;
  }

  static ParsedChoice? _findChoiceByContent(
    List<ParsedChoice> choices,
    String raw,
  ) {
    final target = _norm(raw);
    final foldedTarget = TextNormalizer.accentFolded(target);
    if (target.isEmpty) return null;

    for (final c in choices) {
      if (_norm(c.content) == target) return c;
    }
    for (final c in choices) {
      final folded = TextNormalizer.accentFolded(_norm(c.content));
      if (folded.isNotEmpty && folded == foldedTarget) return c;
    }
    for (final c in choices) {
      final current = _norm(c.content);
      if (current.isEmpty) continue;
      if (_nearMatch(target, current) ||
          _nearMatch(foldedTarget, TextNormalizer.accentFolded(current))) {
        return c;
      }
    }
    return null;
  }

  static bool _sameContent(String? a, String? b) {
    if (a == null || b == null) return a == b;
    return _norm(a) == _norm(b);
  }

  static String _norm(String raw) {
    return TextNormalizer.normalizeAnswerForCompare(raw)
        .replaceAll(r'$', '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  static bool _nearMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length < 4) return false;
    return longer.contains(shorter);
  }
}
