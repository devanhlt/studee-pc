/// Client-side enrichers so question text renders as math / code in [StudyMarkdown].
///
/// Handles common stored/OCR forms like Python nested lists `[[1,2],[3,4]]`
/// without requiring an extra LLM round-trip (LLM LaTeX still preferred when present).
abstract final class QuestionDisplayFormat {
  /// Convert display-hostile math/code shapes into Markdown + LaTeX.
  static String enrich(String input) {
    if (input.trim().isEmpty) return input;
    var text = input.replaceAll('\r\n', '\n');
    text = _pythonMatricesToLatex(text);
    return text;
  }

  /// Build a markdown preview from a structured parse (stem + choices).
  static String fromParsed({
    required String content,
    List<({String label, String content})> choices = const [],
  }) {
    final buf = StringBuffer();
    buf.write(enrich(content.trim()));
    if (choices.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      for (final c in choices) {
        final label = c.label.trim();
        final body = enrich(c.content.trim());
        if (label.isEmpty) {
          buf.writeln(body);
        } else if (body.isEmpty) {
          buf.writeln(label);
        } else {
          buf.writeln('$label. $body');
        }
      }
    }
    return buf.toString().trim();
  }

  /// `[[a,b],[c,d]]` → `$\begin{bmatrix}a & b \\ c & d\end{bmatrix}$`
  static String _pythonMatricesToLatex(String text) {
    if (!text.contains('[[')) return text;

    final matrixRe = RegExp(
      r'(?:([A-Za-z][A-Za-z0-9]*)\s*=\s*)?'
      r'(\[\s*\[[^\[\]]*\](?:\s*,\s*\[[^\[\]]*\])+\s*\])',
    );

    return _mapOutsideProtected(text, (segment) {
      return segment.replaceAllMapped(matrixRe, (m) {
        final name = m.group(1);
        final raw = m.group(2)!;
        final latex = _listLiteralToBmatrix(raw);
        if (latex == null) return m.group(0)!;
        if (name != null && name.isNotEmpty) {
          return '\$$name = $latex\$';
        }
        return '\$$latex\$';
      });
    });
  }

  static String? _listLiteralToBmatrix(String literal) {
    final trimmed = literal.trim();
    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return null;
    final inner = trimmed.substring(1, trimmed.length - 1).trim();
    final rowRe = RegExp(r'\[([^\[\]]*)\]');
    final rows = <String>[];
    for (final m in rowRe.allMatches(inner)) {
      final cells = m
          .group(1)!
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .map(_cellToTex)
          .toList();
      if (cells.isEmpty) return null;
      rows.add(cells.join(' & '));
    }
    if (rows.length < 2) return null;
    return '\\begin{bmatrix}${rows.join(r' \\ ')}\\end{bmatrix}';
  }

  static String _cellToTex(String cell) {
    var c = cell.trim();
    // Already TeX-ish — leave alone.
    if (c.contains(r'\') || c.contains('{')) return c;
    c = c.replaceAll('−', '-');
    // Fractions a/b → \frac{a}{b} for simple integers.
    final frac = RegExp(r'^(-?\d+)\s*/\s*(-?\d+)$').firstMatch(c);
    if (frac != null) {
      return '\\frac{${frac.group(1)}}{${frac.group(2)}}';
    }
    return c;
  }

  /// Apply [map] only outside ``` fences and `$` / `$$` / `\(...\)` / `\[...\]`.
  static String _mapOutsideProtected(
    String text,
    String Function(String segment) map,
  ) {
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      // Code fence
      if (text.startsWith('```', i)) {
        final end = text.indexOf('```', i + 3);
        if (end < 0) {
          out.write(text.substring(i));
          break;
        }
        out.write(text.substring(i, end + 3));
        i = end + 3;
        continue;
      }
      // Display $$
      if (text.startsWith(r'$$', i)) {
        final end = text.indexOf(r'$$', i + 2);
        if (end < 0) {
          out.write(map(text.substring(i)));
          break;
        }
        out.write(text.substring(i, end + 2));
        i = end + 2;
        continue;
      }
      // Inline $
      if (text[i] == r'$') {
        final end = text.indexOf(r'$', i + 1);
        if (end < 0) {
          out.write(map(text.substring(i)));
          break;
        }
        out.write(text.substring(i, end + 1));
        i = end + 1;
        continue;
      }
      // \( ... \)
      if (text.startsWith(r'\(', i)) {
        final end = text.indexOf(r'\)', i + 2);
        if (end < 0) {
          out.write(map(text.substring(i)));
          break;
        }
        out.write(text.substring(i, end + 2));
        i = end + 2;
        continue;
      }
      // \[ ... \]
      if (text.startsWith(r'\[', i)) {
        final end = text.indexOf(r'\]', i + 2);
        if (end < 0) {
          out.write(map(text.substring(i)));
          break;
        }
        out.write(text.substring(i, end + 2));
        i = end + 2;
        continue;
      }

      // Plain run until next protector.
      final next = _nextProtector(text, i + 1);
      out.write(map(text.substring(i, next)));
      i = next;
    }
    return out.toString();
  }

  static int _nextProtector(String text, int from) {
    var best = text.length;
    for (final token in ['```', r'$$', r'$', r'\(', r'\[']) {
      final idx = text.indexOf(token, from);
      if (idx >= 0 && idx < best) best = idx;
    }
    return best;
  }
}
