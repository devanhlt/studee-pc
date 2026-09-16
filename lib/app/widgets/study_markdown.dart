import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_typography.dart';
import 'package:studee_pc/app/widgets/question_display_format.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';

/// Renders study markdown with LaTeX (`$…$`, `$$…$$`, `\(...\)`, `\[…\]`).
///
/// Use anywhere formulas appear: explanations, answers, knowledge, questions.
/// Wide formulas scroll horizontally instead of overflowing the layout.
class StudyMarkdown extends StatelessWidget {
  const StudyMarkdown(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.compact = false,
    this.textAlign,
    this.formatKind = SubjectFormatKind.plain,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final bool compact;
  final TextAlign? textAlign;
  final SubjectFormatKind formatKind;

  /// True when [text] likely contains LaTeX or markdown worth rendering.
  static bool looksStructured(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final t = text;
    return t.contains(r'$') ||
        t.contains(r'\(') ||
        t.contains(r'\[') ||
        t.contains('[[') ||
        RegExp(r'\([^)]*;[^)]*\)').hasMatch(t) ||
        t.contains('```') ||
        t.contains('**') ||
        t.contains('##') ||
        t.contains('\n- ') ||
        t.contains('\n* ') ||
        RegExp(r'`[^`]+`').hasMatch(t);
  }

  @override
  Widget build(BuildContext context) {
    final prepared = _prepareLatex(data, kind: formatKind);
    if (prepared.trim().isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context).textTheme;
    final baseStyle = style ??
        (compact
            ? theme.bodyMedium?.copyWith(
                  color: AppColors.primaryText,
                  height: 1.55,
                )
            : theme.bodyLarge?.copyWith(
                  color: AppColors.primaryText,
                  height: 1.55,
                )) ??
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontFamilyFallback: AppTypography.fontFamilyFallback,
          color: AppColors.primaryText,
          height: 1.55,
          fontSize: compact ? 15 : 16,
        );

    // Plain subjects: avoid markdown/math pipeline — show text as-is.
    if (formatKind == SubjectFormatKind.plain &&
        !looksStructured(prepared)) {
      return Text(
        prepared,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
        textAlign: textAlign,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final maxContentW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (screenW - 48).clamp(160.0, screenW);

        return GptMarkdown(
          prepared,
          style: baseStyle,
          textAlign: textAlign,
          useDollarSignsForLatex: formatKind == SubjectFormatKind.math,
          maxLines: maxLines,
          overflow:
              maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
          styleSheet: const GptMarkdownStyleSheet(
            latex: LatexStyle(scrollBlockHorizontally: true),
          ),
          latexWorkaround: _latexWorkaround,
          // 4th arg from gpt_markdown is `inline` (true = $…$, false = $$…$$).
          latexBuilder: (context, tex, textStyle, inline) {
            return _FormulaBox(
              tex: _latexWorkaround(tex),
              textStyle: textStyle,
              inline: inline,
              maxWidth: maxContentW,
            );
          },
        );
      },
    );
  }

  /// Normalize common model / OCR LaTeX quirks before rendering.
  static String prepareForRender(
    String input, {
    SubjectFormatKind kind = SubjectFormatKind.plain,
  }) =>
      _prepareLatex(input, kind: kind);

  /// Strip delimiters and fix common Unicode/math mixups for the TeX engine.
  static String normalizeTex(String tex) => _latexWorkaround(tex);

  /// Normalize common model / OCR LaTeX quirks before rendering.
  static String _prepareLatex(
    String input, {
    SubjectFormatKind kind = SubjectFormatKind.plain,
  }) {
    var text = QuestionDisplayFormat.enrich(
      input.replaceAll('\r\n', '\n'),
      kind: kind,
    );
    if (kind != SubjectFormatKind.math) {
      return text.trim();
    }

    // Some models emit \\( \\) with double backslashes still escaped.
    text = text.replaceAll(r'\\(', r'\(').replaceAll(r'\\)', r'\)');
    text = text.replaceAll(r'\\[', r'\[').replaceAll(r'\\]', r'\]');

    // Ensure display blocks have blank lines so markdown parsers treat them
    // as block math rather than inline (avoids mid-line overflow).
    text = text.replaceAllMapped(
      RegExp(r'(?<!\$)\$\$([\s\S]+?)\$\$(?!\$)'),
      (m) => '\n\n\$\$${m[1]!.trim()}\$\$\n\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'\\\[([\s\S]+?)\\\]'),
      (m) => '\n\n\\[${m[1]!.trim()}\\]\n\n',
    );

    return text.trim();
  }

  static String _latexWorkaround(String tex) {
    var t = tex.trim();
    // Strip leftover delimiters if the builder received them.
    if (t.startsWith(r'$$') && t.endsWith(r'$$') && t.length >= 4) {
      t = t.substring(2, t.length - 2).trim();
    } else if (t.startsWith(r'\(') && t.endsWith(r'\)') && t.length >= 4) {
      t = t.substring(2, t.length - 2).trim();
    } else if (t.startsWith(r'$') && t.endsWith(r'$') && t.length >= 2) {
      t = t.substring(1, t.length - 1).trim();
    }
    // Common DeepSeek / Unicode mixups.
    t = t
        .replaceAll('−', '-')
        .replaceAll('×', r'\times ')
        .replaceAll('÷', r'\div ')
        .replaceAll('≤', r'\le ')
        .replaceAll('≥', r'\ge ')
        .replaceAll('≠', r'\ne ');
    return t;
  }
}

/// Math widget that scrolls horizontally when wider than [maxWidth].
class _FormulaBox extends StatelessWidget {
  const _FormulaBox({
    required this.tex,
    required this.textStyle,
    required this.inline,
    required this.maxWidth,
  });

  final String tex;
  final TextStyle textStyle;
  final bool inline;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final baseSize = textStyle.fontSize ?? (inline ? 15.0 : 16.0);
    // Formulas render smaller than body text at the same point size on mobile.
    // Desktop already looks oversized at that bump — keep mobile as-is.
    final sizeScale = _isDesktop
        ? (inline ? 1.0 : 1.1)
        : (inline ? 1.25 : 1.4);
    final mathTextStyle = textStyle.copyWith(fontSize: baseSize * sizeScale);

    final math = Math.tex(
      tex,
      textStyle: mathTextStyle,
      mathStyle: inline ? MathStyle.text : MathStyle.display,
      onErrorFallback: (_) => SelectableText(
        inline ? '\$$tex\$' : '\$\$$tex\$\$',
        style: mathTextStyle.merge(AppTypography.mono),
      ),
    );

    final scrollable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: math,
    );

    final boxed = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: scrollable,
    );

    if (inline) return boxed;

    // Block formulas: own line + vertical breathing room + horizontal scroll.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: boxed,
      ),
    );
  }
}

bool get _isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
