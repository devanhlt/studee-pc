/// Client-side enrichers so question text renders as math / code in [StudyMarkdown].
///
/// Handles common stored/OCR forms like Python nested lists `[[1,2],[3,4]]`
/// and MATLAB-style `( 1 2 ; 3 4 )` without an extra LLM round-trip.
abstract final class QuestionDisplayFormat {
  /// Convert display-hostile math/code shapes into Markdown + LaTeX.
  static String enrich(String input) {
    if (input.trim().isEmpty) return input;
    var text = input.replaceAll('\r\n', '\n');
    text = _pythonMatricesToLatex(text);
    text = _matlabMatricesToLatex(text);
    text = _equationSystemsToLatex(text);
    text = _assignmentListsToLatex(text);
    text = _transposeProductsToLatex(text);
    text = _bareSubscriptsToLatex(text);
    return text;
  }

  /// True when text still looks like raw exam math that needs LaTeX polish.
  static bool needsLatexPolish(String? text) {
    if (text == null) return false;
    final t = text.trim();
    if (t.isEmpty) return false;

    // Raw python / MATLAB matrices still present.
    if (t.contains('[[') && !t.contains(r'\begin{bmatrix}')) return true;
    if (RegExp(r'\(\s*-?\d[^)]*;[^)]*\)').hasMatch(t) &&
        !t.contains(r'\begin{bmatrix}')) {
      return true;
    }
    // Equation system still in `{ eq ; eq }` form.
    if (RegExp(r'\{[^{};]*;[^}]*[})]').hasMatch(t)) return true;
    // Bare variable subscripts like x1 / 3x2 (not already x_{1}).
    if (RegExp(
      r'(?<![A-Za-z\\])([xyzuvwabcdmnkijXYZUVWABCDMNKIJ])\d+(?!\d)',
    ).hasMatch(t)) {
      return true;
    }
    // Transpose products still dotted.
    if (RegExp(r'\b[A-Za-z]\.[A-Za-z]?T\b').hasMatch(t)) return true;
    // Assignment lists without math delimiters.
    if (RegExp(
          r'(?<!\$)\b[xyzuvwabcdmnkij]\d+\s*=\s*-?\d+',
          caseSensitive: false,
        ).hasMatch(t) &&
        !t.contains(r'$')) {
      return true;
    }
    return false;
  }

  /// True if stem or any choice still needs LaTeX.
  static bool bundleNeedsLatexPolish({
    required String content,
    List<String> choiceContents = const [],
    String? answerContent,
  }) {
    if (needsLatexPolish(content)) return true;
    if (choiceContents.any(needsLatexPolish)) return true;
    return needsLatexPolish(answerContent);
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

  /// MATLAB / Octave: `( 1 1 -2 ; 0 1 3 )` → bmatrix LaTeX.
  static String _matlabMatricesToLatex(String text) {
    if (!text.contains(';') || !text.contains('(')) return text;

    // Optional "A = " then ( row ; row … ). Rows use spaces and/or commas.
    final matrixRe = RegExp(
      r'(?:([A-Za-z][A-Za-z0-9]*)\s*=\s*)?'
      r'\(\s*'
      r'('
      r'-?[0-9]+(?:\.[0-9]+)?(?:\s*,?\s+-?[0-9]+(?:\.[0-9]+)?)*'
      r'(?:\s*;\s*-?[0-9]+(?:\.[0-9]+)?(?:\s*,?\s+-?[0-9]+(?:\.[0-9]+)?)*)+'
      r')'
      r'\s*\)',
    );

    return _mapOutsideProtected(text, (segment) {
      return segment.replaceAllMapped(matrixRe, (m) {
        final name = m.group(1);
        final inner = m.group(2)!;
        final latex = _matlabInnerToBmatrix(inner);
        if (latex == null) return m.group(0)!;
        if (name != null && name.isNotEmpty) {
          return '\$$name = $latex\$';
        }
        return '\$$latex\$';
      });
    });
  }

  /// `A.AT` / `A.A^T` → `$A A^{T}$`
  static String _transposeProductsToLatex(String text) {
    return _mapOutsideProtected(text, (segment) {
      var s = segment;
      // A.AT or A.A^T or A*AT (same letter)
      s = s.replaceAllMapped(
        RegExp(
          r'\b([A-Za-z])\s*(?:[·⋅*]|\.)\s*\1\s*(?:\^\s*)?[Tt]\b',
        ),
        (m) => '\$${m[1]} ${m[1]}^{T}\$',
      );
      // Bare A^T not already in math
      s = s.replaceAllMapped(
        RegExp(r'(?<!\$)\b([A-Za-z])\s*\^\s*[Tt]\b'),
        (m) => '\$${m[1]}^{T}\$',
      );
      return s;
    });
  }

  /// `{ eq1 ; eq2 ; eq3 )` / `{…}` → display cases block.
  static String _equationSystemsToLatex(String text) {
    if (!text.contains(';')) return text;
    final systemRe = RegExp(
      r'\{([^{};]+(?:;[^{};]+)+)[})]',
    );
    return _mapOutsideProtected(text, (segment) {
      return segment.replaceAllMapped(systemRe, (m) {
        final inner = m.group(1)!;
        final eqs = inner
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map(_equationLineToTex)
            .toList();
        if (eqs.length < 2) return m.group(0)!;
        final body = eqs.join(r' \\ ');
        return '\n\n\$\$\\begin{cases}$body\\end{cases}\$\$\n\n';
      });
    });
  }

  /// `x1=1,x2=1,x3=-1` → `$x_1=1,\ x_2=1,\ x_3=-1$`
  static String _assignmentListsToLatex(String text) {
    final assignRe = RegExp(
      r'(?<!\$)\b((?:[xyzuvwabcdmnkijXYZUVWABCDMNKIJ]\d+\s*=\s*-?\d+(?:\.\d+)?)'
      r'(?:\s*,\s*[xyzuvwabcdmnkijXYZUVWABCDMNKIJ]\d+\s*=\s*-?\d+(?:\.\d+)?){1,})',
    );
    return _mapOutsideProtected(text, (segment) {
      return segment.replaceAllMapped(assignRe, (m) {
        final raw = m.group(1)!;
        final parts = raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
        final tex = parts.map((p) {
          final eq = RegExp(
            r'^([A-Za-z])(\d+)\s*=\s*(-?\d+(?:\.\d+)?)$',
          ).firstMatch(p);
          if (eq == null) return _subscriptsInMath(p);
          return '${eq.group(1)}_{${eq.group(2)}}=${eq.group(3)}';
        }).join(r',\ ');
        return '\$$tex\$';
      });
    });
  }

  /// Remaining bare `x1` tokens → `$x_1$` (outside existing math).
  static String _bareSubscriptsToLatex(String text) {
    // No leading \b: coefficients glue as `3x2` (digit+letter is still \w).
    final varRe = RegExp(
      r'(?<![A-Za-z\\])([xyzuvwabcdmnkijXYZUVWABCDMNKIJ])(\d+)(?!\d)',
    );
    return _mapOutsideProtected(text, (segment) {
      return segment.replaceAllMapped(
        varRe,
        (m) => '\$${m[1]}_{${m[2]}}\$',
      );
    });
  }

  static String _equationLineToTex(String line) {
    var t = line.trim();
    t = _subscriptsInMath(t);
    // Light spacing around = + -
    t = t.replaceAllMapped(
      RegExp(r'\s*([=+\-])\s*'),
      (m) => ' ${m[1]} ',
    );
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _subscriptsInMath(String s) {
    // Match x1 even when glued to a coefficient (`3x2`).
    return s.replaceAllMapped(
      RegExp(
        r'(?<![A-Za-z\\])([xyzuvwabcdmnkijXYZUVWABCDMNKIJ])(\d+)(?!\d)',
      ),
      (m) => '${m[1]}_{${m[2]}}',
    );
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

  static String? _matlabInnerToBmatrix(String inner) {
    final rows = <String>[];
    for (final row in inner.split(';')) {
      final cells = row
          .trim()
          .split(RegExp(r'[\s,]+'))
          .where((c) => c.isNotEmpty)
          .map(_cellToTex)
          .toList();
      if (cells.isEmpty) return null;
      rows.add(cells.join(' & '));
    }
    if (rows.length < 2) return null;
    // Consistent column count preferred but not required for display.
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
