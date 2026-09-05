import 'package:equatable/equatable.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';

/// Maps stored answer content onto the **current** choice label.
///
/// Prefer content matching (reorder-safe). When content cannot be remapped
/// (OCR/LaTeX drift), keep the stored answer text rather than discarding
/// imported knowledge — never remap by label alone (that breaks reorders).
class ChoiceMapper {
  const ChoiceMapper();

  /// Returns the current label whose content matches [storedAnswerContent].
  String? mapAnswerContentToCurrentLabel({
    required String? storedAnswerContent,
    required List<ParsedChoice> currentChoices,
    bool allowAccentFold = true,
  }) {
    if (storedAnswerContent == null || storedAnswerContent.trim().isEmpty) {
      return null;
    }
    if (currentChoices.isEmpty) return null;

    final target = _normalizeForMatch(storedAnswerContent);
    final foldedTarget = TextNormalizer.accentFolded(target);

    for (final choice in currentChoices) {
      final current = _normalizeForMatch(choice.content);
      if (current == target) return choice.label;
    }

    if (allowAccentFold) {
      for (final choice in currentChoices) {
        final folded = TextNormalizer.accentFolded(_normalizeForMatch(choice.content));
        if (folded == foldedTarget && folded.isNotEmpty) {
          return choice.label;
        }
      }
    }

    // Contained / near match (OCR / LaTeX drift).
    for (final choice in currentChoices) {
      final current = _normalizeForMatch(choice.content);
      final folded = TextNormalizer.accentFolded(current);
      if (current.isEmpty) continue;
      if (_nearMatch(target, current) || _nearMatch(foldedTarget, folded)) {
        return choice.label;
      }
    }

    return null;
  }

  /// Resolves both label and content for the current question.
  MappedAnswer? mapStoredAnswer({
    required String? storedAnswerContent,
    required String? storedAnswerLabel,
    required ParsedQuestion currentQuestion,
    bool allowAccentFold = true,
  }) {
    final content = storedAnswerContent?.trim();
    final label = storedAnswerLabel?.trim();

    if (currentQuestion.choices.isEmpty) {
      if (content == null || content.isEmpty) return null;
      return MappedAnswer(
        label: null,
        content: content,
        matchedByContent: true,
      );
    }

    final mappedLabel = mapAnswerContentToCurrentLabel(
      storedAnswerContent: content,
      currentChoices: currentQuestion.choices,
      allowAccentFold: allowAccentFold,
    );

    if (mappedLabel != null) {
      final matched = currentQuestion.choices.firstWhere(
        (c) => c.label == mappedLabel,
      );
      return MappedAnswer(
        label: mappedLabel,
        content: matched.content.isNotEmpty
            ? matched.content
            : (content ?? matched.content),
        matchedByContent: true,
        ignoredStoredLabel: label,
      );
    }

    // Keep imported answer text even when choice bodies drifted enough that
    // remapping failed. Do NOT trust stored letter alone (reorder hazard).
    if (content != null && content.isNotEmpty) {
      return MappedAnswer(
        label: label,
        content: content,
        matchedByContent: false,
        ignoredStoredLabel: label,
      );
    }

    return null;
  }

  /// Strip LaTeX markers / whitespace noise for robust MC matching.
  static String _normalizeForMatch(String raw) {
    var s = TextNormalizer.stripChoicePrefix(raw);
    s = s
        .replaceAll(r'$', '')
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll('_', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll(RegExp(r'\s+'), '');
    return s.toLowerCase();
  }

  static bool _nearMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    // Tolerate short suffix/prefix OCR noise.
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length < 4) return false;
    return longer.contains(shorter);
  }
}

/// Result of mapping a stored answer onto the live choice set.
class MappedAnswer extends Equatable {
  const MappedAnswer({
    required this.label,
    required this.content,
    required this.matchedByContent,
    this.ignoredStoredLabel,
  });

  final String? label;
  final String content;
  final bool matchedByContent;
  final String? ignoredStoredLabel;

  @override
  List<Object?> get props =>
      [label, content, matchedByContent, ignoredStoredLabel];
}
