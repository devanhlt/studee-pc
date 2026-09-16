import 'package:studee_pc/app/widgets/question_display_format.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';

/// Formats Q&A field text so Markdown/PDF can render code fences and LaTeX.
abstract final class StudyNotesMarkdownCode {
  /// True when [raw] is best shown as a code snippet (not prose/markdown).
  static bool isCodeSnippet(
    String raw, {
    SubjectFormatKind kind = SubjectFormatKind.plain,
  }) {
    if (kind == SubjectFormatKind.plain) return false;
    if (kind == SubjectFormatKind.math) {
      // Only treat as code when it clearly is (rare in math subjects).
      final t = QuestionDisplayFormat.repairSpuriousMathInCode(raw).trim();
      return QuestionDisplayFormat.looksLikeSourceCode(t);
    }
    final t = QuestionDisplayFormat.repairSpuriousMathInCode(raw).trim();
    if (t.isEmpty) return false;
    if (t.contains('```')) return true;
    return looksLikeCode(t) && t.length < 800;
  }

  /// Plain source for monospace display (fences stripped).
  static String codeSnippetBody(String raw) {
    var t = QuestionDisplayFormat.repairSpuriousMathInCode(raw).trim();
    final fenced = RegExp(
      r'^```[^\n]*\n([\s\S]*?)```\s*$',
    ).firstMatch(t);
    if (fenced != null) {
      t = fenced.group(1)!.trimRight();
    } else {
      t = t
          .replaceAll(RegExp(r'^```[^\n]*\n?'), '')
          .replaceAll(RegExp(r'\n?```\s*$'), '')
          .trim();
    }
    return prettifyFlattenedCode(t);
  }

  /// Process question or answer body for display / export.
  static String formatBody(
    String raw, {
    SubjectFormatKind kind = SubjectFormatKind.plain,
  }) {
    final normalized = _normalizeQuotes(raw.replaceAll('\r\n', '\n')).trim();
    if (normalized.isEmpty) return normalized;

    switch (kind) {
      case SubjectFormatKind.plain:
        return normalized;
      case SubjectFormatKind.code:
        return _formatCodeBody(normalized);
      case SubjectFormatKind.math:
        return _formatMathBody(normalized);
    }
  }

  static String _formatCodeBody(String text) {
    final repaired = QuestionDisplayFormat.repairSpuriousMathInCode(text);
    if (repaired.contains('```')) {
      return _normalizeFencedCodePlaceholders(repaired);
    }
    final split = splitProseAndCode(repaired);
    if (split != null) {
      final buf = StringBuffer();
      if (split.prose.trim().isNotEmpty) {
        buf.writeln(split.prose.trim());
        buf.writeln();
      }
      buf.writeln('```${split.lang}');
      buf.writeln(split.code.trimRight());
      buf.writeln('```');
      return buf.toString().trimRight();
    }
    if (looksLikeCode(repaired) ||
        QuestionDisplayFormat.looksLikeSourceCode(repaired)) {
      final lang = guessLanguage(repaired);
      final code = prettifyFlattenedCode(repaired);
      return '```$lang\n$code\n```';
    }
    return repaired;
  }

  static String _formatMathBody(String text) {
    final repaired = QuestionDisplayFormat.repairSpuriousMathInCode(text);
    if (repaired.contains('```')) {
      return _prepareOutsideCodeFences(
        _normalizeFencedCodePlaceholders(repaired),
        kind: SubjectFormatKind.math,
      );
    }

    final split = splitProseAndCode(repaired);
    if (split != null) {
      final buf = StringBuffer();
      final prose = StudyMarkdown.prepareForRender(
        split.prose,
        kind: SubjectFormatKind.math,
      ).trim();
      if (prose.isNotEmpty) {
        buf.writeln(prose);
        buf.writeln();
      }
      buf.writeln('```${split.lang}');
      buf.writeln(split.code.trimRight());
      buf.writeln('```');
      return buf.toString().trimRight();
    }

    if (looksLikeCode(repaired) &&
        QuestionDisplayFormat.looksLikeSourceCode(repaired)) {
      final lang = guessLanguage(repaired);
      final code = prettifyFlattenedCode(repaired);
      return '```$lang\n$code\n```';
    }

    return StudyMarkdown.prepareForRender(
      repaired,
      kind: SubjectFormatKind.math,
    ).trim();
  }

  /// ASCII-normalize ellipsis placeholders inside ``` fences only.
  static String _normalizeFencedCodePlaceholders(String text) {
    final re = RegExp(r'```([^\n`]*)\n([\s\S]*?)```');
    return text.replaceAllMapped(re, (m) {
      final lang = m[1] ?? '';
      final code = prettifyFlattenedCode(m[2] ?? '');
      return '```$lang\n$code\n```';
    });
  }

  static String _normalizeQuotes(String text) {
    return text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('″', '"')
        .replaceAll('′', "'");
  }

  /// Apply LaTeX prep only outside ``` fences.
  static String _prepareOutsideCodeFences(
    String text, {
    SubjectFormatKind kind = SubjectFormatKind.math,
  }) {
    final parts = <String>[];
    final re = RegExp(r'```[\s\S]*?```');
    var start = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > start) {
        parts.add(
          StudyMarkdown.prepareForRender(
            text.substring(start, m.start),
            kind: kind,
          ),
        );
      }
      parts.add(m.group(0)!);
      start = m.end;
    }
    if (start < text.length) {
      parts.add(
        StudyMarkdown.prepareForRender(text.substring(start), kind: kind),
      );
    }
    return parts.join().trim();
  }

  static bool looksLikeCode(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (RegExp(r'#include\s*[<"]').hasMatch(t)) return true;
    if (RegExp(r'\bint\s+main\s*\(').hasMatch(t)) return true;
    if (RegExp(
      r'\b(void|int|char|float|double|long|short|bool|unsigned|FILE)\s+\*?\s*\w+\s*\([^;{]*\)\s*\{',
    ).hasMatch(t)) {
      return true;
    }
    if (RegExp(
          r'\b(printf|scanf|malloc|free|strcpy|fopen|fprintf|stricmp|strcmp)\s*\(',
        ).hasMatch(t) &&
        (t.contains(';') || t.contains('{'))) {
      return true;
    }
    if (RegExp(r'\btypedef\s+struct\b').hasMatch(t)) return true;
    if (RegExp(r'\b(def|class|import|from)\s+\w+').hasMatch(t) &&
        (t.contains(':') || t.contains('('))) {
      return true;
    }
    if (RegExp(r'\b(public|private|static)\s+(class|void|int)').hasMatch(t)) {
      return true;
    }

    final list = t
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (list.length >= 3) {
      var codeLines = 0;
      for (final l in list) {
        if (_lineLooksCode(l)) codeLines++;
      }
      if (codeLines >= (list.length * 0.5).ceil()) return true;
    }
    return false;
  }

  static bool _lineLooksCode(String line) {
    final t = line.trim();
    if (t.contains(';')) return true;
    if (t == '{' || t == '}' || t.startsWith('}') || t.endsWith('{')) {
      return true;
    }
    if (RegExp(
      r'^(if|for|while|else|return|printf|scanf|else\s+if)\b',
    ).hasMatch(t)) {
      return true;
    }
    if (RegExp(r'^(#include|#define|using\s+namespace|typedef)').hasMatch(t)) {
      return true;
    }
    return false;
  }

  static String guessLanguage(String text) {
    final t = text;
    if (RegExp(r'#include\s*[<"]').hasMatch(t) ||
        RegExp(r'\b(printf|scanf|malloc|fopen|strcpy|stricmp)\s*\(')
            .hasMatch(t) ||
        RegExp(r'\btypedef\s+struct\b').hasMatch(t)) {
      return 'c';
    }
    if (RegExp(r'\b(def|import|print)\b').hasMatch(t) &&
        !RegExp(r'#include').hasMatch(t)) {
      return 'python';
    }
    if (RegExp(r'\b(public\s+class|System\.out)\b').hasMatch(t)) {
      return 'java';
    }
    if (RegExp(r'\b(fn\s+|let\s+mut|println!)\b').hasMatch(t)) return 'rust';
    if (RegExp(r'\b(function|const|let|=>)\b').hasMatch(t)) return 'javascript';
    return 'c';
  }

  /// Split leading prose/question from trailing source code.
  static ({String prose, String code, String lang})? splitProseAndCode(
    String text,
  ) {
    final t = text.trim();

    // Mid-string / flattened: "... gì? #include..." or "... gì? int main..."
    final flatPatterns = <RegExp>[
      RegExp(
        r'^(.+?[?？])\s*(#include\b[\s\S]+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?[?？])\s*(int\s+main\s*\([\s\S]+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?[?？])\s*((?:void|int|char|float|double|FILE)\s+\*?\s*\w+\s*\([\s\S]+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?(?:chương trình sau|program below|sau đây|như sau)\s*[.:]?)\s*(#include\b[\s\S]+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?(?:chương trình sau|program below|sau đây|như sau)\s*[.:]?)\s*(int\s+main\s*\([\s\S]+)$',
        caseSensitive: false,
      ),
    ];
    for (final re in flatPatterns) {
      final m = re.firstMatch(t);
      if (m == null) continue;
      final prose = m.group(1)!.trim();
      final code = prettifyFlattenedCode(m.group(2)!.trim());
      if (prose.length >= 8 && looksLikeCode(code)) {
        return (prose: prose, code: code, lang: guessLanguage(code));
      }
    }

    // Multiline markers at line starts.
    final markers = <RegExp>[
      RegExp(r'(?:^|\n)\s*(#include\s*[<"])'),
      RegExp(r'(?:^|\n)\s*(int\s+main\s*\()'),
      RegExp(
        r'(?:^|\n)\s*((?:void|int|char|float|double|FILE)\s+\*?\s*\w+\s*\([^;{]*\)\s*\{)',
      ),
    ];
    for (final re in markers) {
      final m = re.firstMatch(t);
      if (m == null) continue;
      final g1 = m.group(1)!;
      final codeStart = t.indexOf(g1, m.start);
      if (codeStart < 0) continue;
      final prose = t.substring(0, codeStart).trim();
      final code = prettifyFlattenedCode(t.substring(codeStart).trim());
      if (prose.length < 8) continue;
      if (looksLikeCode(code)) {
        return (prose: prose, code: code, lang: guessLanguage(code));
      }
    }

    return null;
  }

  /// Pretty-print flattened or left-aligned C-like snippets with brace indent.
  static String prettifyFlattenedCode(String code) {
    var trimmed = _normalizeCodePlaceholders(code.trim());
    if (trimmed.isEmpty) return trimmed;
    if (!looksLikeCode(trimmed)) {
      return _breakAfterPlaceholders(trimmed);
    }
    if (!_needsIndentFix(trimmed)) {
      return _breakAfterPlaceholders(
        trimmed
            .split('\n')
            .map((l) => l.trimRight())
            .where((l) => l.trim().isNotEmpty)
            .join('\n'),
      );
    }

    trimmed = trimmed.replaceAllMapped(
      RegExp(r'#include\s*<([^>]+)>'),
      (m) => '#include <${m[1]}>',
    );
    trimmed = trimmed.replaceAllMapped(
      RegExp(r'#include\s*"([^"]+)"'),
      (m) => '#include "${m[1]}"',
    );

    // Collapse to one line outside strings, then re-indent from structure.
    trimmed = _collapseOutsideStrings(trimmed);
    trimmed = trimmed.replaceAllMapped(
      RegExp(r'(#include\s*[<"][^>"]+[>"])\s*(#include)'),
      (m) => '${m[1]}\n${m[2]}',
    );
    trimmed = trimmed.replaceAllMapped(
      RegExp(r'(#include\s*[<"][^>"]+[>"])\s+'),
      (m) => '${m[1]}\n',
    );

    final buf = StringBuffer();
    var indent = 0;
    var paren = 0;
    // Stack: true = block brace (newline+indent), false = initializer `{...}`.
    final braceIsBlock = <bool>[];
    var i = 0;
    var inString = false;
    var stringQuote = '';

    void newline() {
      buf.write('\n');
      buf.write('  ' * indent);
    }

    void skipSpaces() {
      while (i < trimmed.length && (trimmed[i] == ' ' || trimmed[i] == '\t')) {
        i++;
      }
    }

    String? lastNonSpace() {
      final s = buf.toString();
      for (var j = s.length - 1; j >= 0; j--) {
        final ch = s[j];
        if (ch != ' ' && ch != '\t' && ch != '\n') return ch;
      }
      return null;
    }

    while (i < trimmed.length) {
      final ch = trimmed[i];

      if (ch == '\n') {
        // Keep #include lines separate; collapse other newlines.
        final s = buf.toString();
        final lineStart = s.lastIndexOf('\n') + 1;
        final line = s.substring(lineStart).trimLeft();
        if (line.startsWith('#include')) {
          indent = 0;
          newline();
        } else if (buf.isNotEmpty && !s.endsWith(' ') && !s.endsWith('\n')) {
          buf.write(' ');
        }
        i++;
        skipSpaces();
        continue;
      }

      if (inString) {
        buf.write(ch);
        if (ch == '\\' && i + 1 < trimmed.length) {
          buf.write(trimmed[i + 1]);
          i += 2;
          continue;
        }
        if (ch == stringQuote) inString = false;
        i++;
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringQuote = ch;
        buf.write(ch);
        i++;
        continue;
      }

      if (ch == '(') {
        paren++;
        buf.write(ch);
        i++;
        continue;
      }
      if (ch == ')') {
        paren = paren > 0 ? paren - 1 : 0;
        buf.write(ch);
        i++;
        continue;
      }

      if (ch == '{') {
        final prev = lastNonSpace();
        final isInit = prev == '=' || prev == ',' || prev == '{';
        braceIsBlock.add(!isInit);
        final s = buf.toString();
        if (s.isNotEmpty && !s.endsWith(' ') && !s.endsWith('\n')) {
          buf.write(' ');
        }
        buf.write('{');
        indent++;
        if (!isInit) newline();
        i++;
        skipSpaces();
        continue;
      }

      if (ch == '}') {
        final isBlock =
            braceIsBlock.isNotEmpty ? braceIsBlock.removeLast() : true;
        indent = indent > 0 ? indent - 1 : 0;
        if (isBlock) {
          final s = buf.toString();
          final lastNl = s.lastIndexOf('\n');
          final cur = lastNl >= 0 ? s.substring(lastNl + 1) : s;
          if (cur.trim().isEmpty) {
            // Replace whitespace-only line with the correct outdent.
            if (lastNl >= 0) {
              buf.clear();
              buf.write(s.substring(0, lastNl + 1));
              buf.write('  ' * indent);
            } else {
              buf.clear();
              buf.write('  ' * indent);
            }
          } else {
            // Keep the statement; put `}` on the next line.
            buf.write('\n');
            buf.write('  ' * indent);
          }
          buf.write('}');
        } else {
          buf.write('}');
        }
        i++;
        if (i < trimmed.length && trimmed[i] == ';') {
          buf.write(';');
          i++;
        }
        skipSpaces();
        if (i < trimmed.length && trimmed[i] != '}' && trimmed[i] != '\n') {
          if (isBlock || trimmed[i] != ',') {
            newline();
          }
        }
        continue;
      }

      if (ch == ';' && paren == 0) {
        buf.write(';');
        i++;
        skipSpaces();
        if (i < trimmed.length && trimmed[i] != '}' && trimmed[i] != '\n') {
          newline();
        }
        continue;
      }

      buf.write(ch);
      i++;
    }

    return _breakAfterPlaceholders(
      buf
          .toString()
          .split('\n')
          .map((l) => l.trimRight())
          .where((l) => l.trim().isNotEmpty)
          .join('\n'),
    );
  }

  /// Map Unicode ellipsis / blank markers to ASCII so PDF Courier can render them.
  static String _normalizeCodePlaceholders(String code) {
    return code
        .replaceAll('…', '...')
        .replaceAll('⋯', '...')
        .replaceAll('‥', '..')
        .replaceAll('．', '.');
  }

  /// Keep fill-in blanks (`......`) on their own line before the next statement.
  static String _breakAfterPlaceholders(String code) {
    return code.replaceAllMapped(
      RegExp(
        r'^([ \t]*)(\.{3,})[ \t]+(?=(return|if|for|while|else|printf|scanf|int|char|void|double|float|long)\b)',
        multiLine: true,
      ),
      (m) => '${m[1]}${m[2]}\n${m[1]}',
    );
  }

  /// True when code is flat or left-aligned and needs brace-based indent.
  static bool _needsIndentFix(String code) {
    final lines = code
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return true;
    if (!code.contains('{') && !code.contains(';')) return false;
    final indented =
        lines.where((l) => RegExp(r'^[ \t]+').hasMatch(l)).length;
    if (indented == 0) return true;
    if (RegExp(
      r'\{\s*(int|char|float|double|void|long|short|unsigned|for|while|if|return|printf|scanf|FILE)\b',
    ).hasMatch(code)) {
      return true;
    }
    return indented < (lines.length * 0.2).ceil();
  }

  static String _collapseOutsideStrings(String text) {
    final buf = StringBuffer();
    var inString = false;
    var quote = '';
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        buf.write(ch);
        if (ch == '\\' && i + 1 < text.length) {
          buf.write(text[i + 1]);
          i++;
          continue;
        }
        if (ch == quote) inString = false;
        continue;
      }
      if (ch == '"' || ch == "'") {
        inString = true;
        quote = ch;
        buf.write(ch);
        continue;
      }
      if (ch == '\n' || ch == '\t' || ch == ' ') {
        if (buf.isNotEmpty && !buf.toString().endsWith(' ')) buf.write(' ');
        continue;
      }
      buf.write(ch);
    }
    return buf.toString().trim();
  }
}
