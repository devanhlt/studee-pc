import 'package:studee_pc/core/logging/app_logger.dart';

/// Turns Mathpix OCR Markdown/LaTeX into cleaner text for LLM + UI.
///
/// Mathpix often wraps matrices in `\begin{tabular}` / `\begin{array}` with
/// OCR noise (`A=(`, `),B=(`, empty cells). This rewrites those into
/// `\begin{pmatrix}` — keeping A and B as **two** matrices when side-by-side.
abstract final class MathpixTextNormalizer {
  static final AppLogger _log = AppLogger('MathpixTextNormalizer');

  static final RegExp _tabularRe = RegExp(
    r'\\begin\{(tabular|array)\}(?:\[[^\]]*\])?\{[^}]*\}([\s\S]*?)\\end\{\1\}',
    caseSensitive: false,
  );

  /// Plain OCR: `A=( … ),B=( … )` with whitespace / tabs between entries.
  static final RegExp _plainDualMatrixRe = RegExp(
    r'A\s*=\s*\(\s*([\d\s.,+\-]+)\s*\)\s*,\s*B\s*=\s*\(\s*([\d\s.,+\-]+)\s*\)',
    caseSensitive: false,
  );

  /// Normalize Mathpix `text` field for display and DeepSeek prompts.
  static String normalize(String input) {
    var text = input.replaceAll('\r\n', '\n');
    final before = text;

    text = text.replaceAllMapped(_tabularRe, (m) {
      final body = m.group(2) ?? '';
      final replacement = _tabularToMatrix(body);
      if (replacement == null) {
        _log.info('tabular→matrix: no rewrite (kept raw tabular)');
        return m.group(0)!;
      }
      _log.info('tabular→matrix: rewrote block');
      return replacement;
    });

    text = text.replaceAllMapped(_plainDualMatrixRe, (m) {
      final a = _parsePlainMatrixBody(m.group(1) ?? '');
      final b = _parsePlainMatrixBody(m.group(2) ?? '');
      if (a == null || b == null) return m.group(0)!;
      _log.info('plain A=/B= → two pmatrices (${a.length}x${a.first.length}, ${b.length}x${b.first.length})');
      return '\n\$\$A = ${_toPmatrix(a)}, \\quad B = ${_toPmatrix(b)}\$\$\n';
    });

    // Circle choice markers → plain A/B/C/D.
    text = text.replaceAllMapped(
      RegExp(r'[◯○⚬]\s*([A-Da-d])\s*\.'),
      (m) => '${m[1]!.toUpperCase()}.',
    );

    // Light cleanup of mathbf spacing: 2 A → 2A inside math.
    text = text.replaceAllMapped(
      RegExp(r'\\mathbf\{([^}]+)\}'),
      (m) => '\\mathbf{${m[1]!.replaceAll(RegExp(r'\s+'), '')}}',
    );

    // Collapse 3+ blank lines.
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.trim();

    if (text != before.trim()) {
      _log.info(
        'normalize changed text '
        '(in=${before.length}c out=${text.length}c, '
        'hasA=${text.contains('A =')}, hasB=${text.contains('B =')}, '
        'pmatrixCount=${RegExp(r'\\begin\{pmatrix\}').allMatches(text).length})',
      );
    }
    return text;
  }

  static String? _tabularToMatrix(String body) {
    final rows = _parseRows(body);
    if (rows.isEmpty) return null;

    _log.info(
      'tabular rows=${rows.length} cols=${rows.map((r) => r.length).join(',')}',
    );

    final dual = _tryDualLabeledMatrices(rows);
    if (dual != null) return dual;

    final dualSplit = _tryEvenColumnSplit(rows);
    if (dualSplit != null) return dualSplit;

    final single = _trySingleMatrix(rows);
    if (single != null) return single;

    return null;
  }

  static List<List<String>> _parseRows(String body) {
    final cleaned = body
        .replaceAll(RegExp(r'\\hline'), '')
        .replaceAll(RegExp(r'\\cline\{[^}]*\}'), '')
        .trim();
    if (cleaned.isEmpty) return const [];

    final rawRows = cleaned.split(RegExp(r'\\\\'));
    final rows = <List<String>>[];
    for (final raw in rawRows) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final cells = line.split('&').map(_cleanCell).toList();
      if (cells.every((c) => c.isEmpty)) continue;
      rows.add(cells);
    }
    return rows;
  }

  static String _cleanCell(String cell) {
    var t = cell.trim();
    t = t.replaceAll(RegExp(r'^\$+|\$+$'), '');
    t = t.replaceAllMapped(
      RegExp(r'\\mathrm\{([^}]*)\}'),
      (m) => m[1] ?? '',
    );
    t = t.replaceAllMapped(
      RegExp(r'\\mathbf\{([^}]*)\}'),
      (m) => m[1] ?? '',
    );
    t = t.replaceAll(RegExp(r'\\left|\\right'), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// Side-by-side A / B matrices with OCR labels like `A=(` and `),B=(`.
  static String? _tryDualLabeledMatrices(List<List<String>> rows) {
    final colCount =
        rows.map((r) => r.length).fold<int>(0, (a, b) => a > b ? a : b);
    if (colCount < 6 || rows.length < 2) return null;

    var aLabelCol = -1;
    var bLabelCol = -1;
    for (final row in rows) {
      for (var c = 0; c < row.length; c++) {
        final cell = row[c];
        if (RegExp(r'A\s*=\s*\(?', caseSensitive: false).hasMatch(cell)) {
          aLabelCol = c;
        }
        if (RegExp(r'B\s*=\s*\(?', caseSensitive: false).hasMatch(cell) ||
            RegExp(r'\)\s*,\s*B\s*=\s*\(?', caseSensitive: false)
                .hasMatch(cell)) {
          bLabelCol = c;
        }
      }
    }
    if (aLabelCol < 0 || bLabelCol < 0) {
      _log.info('dual labels not found (aCol=$aLabelCol bCol=$bLabelCol)');
      return null;
    }

    final aCols = <int>[];
    final bCols = <int>[];
    for (var c = 0; c < colCount; c++) {
      final values = rows
          .map((r) => c < r.length ? r[c] : '')
          .where((v) => v.isNotEmpty)
          .toList();
      if (values.isEmpty) continue;
      final numericish =
          values.where(_isNumericToken).length >= (values.length / 2).ceil();
      if (!numericish) continue;
      if (c > aLabelCol && c < bLabelCol) {
        aCols.add(c);
      } else if (c > bLabelCol) {
        bCols.add(c);
      } else if (c < aLabelCol) {
        aCols.add(c);
      }
    }

    if (aCols.isEmpty || bCols.isEmpty) {
      _log.info('dual label cols empty a=$aCols b=$bCols');
      return null;
    }

    final a = _extractMatrix(rows, aCols);
    final b = _extractMatrix(rows, bCols);
    if (a == null || b == null) {
      _log.info('dual extract failed aCols=$aCols bCols=$bCols');
      return null;
    }

    _log.info('dual labeled OK A=${a.length}x${a.first.length} B=${b.length}x${b.first.length}');
    return '\n\$\$A = ${_toPmatrix(a)}, \\quad B = ${_toPmatrix(b)}\$\$\n';
  }

  /// When labels are missing/noisy but the table is clearly two equal-width
  /// numeric blocks (e.g. 3+3 columns), emit A and B separately — never one
  /// wide matrix.
  static String? _tryEvenColumnSplit(List<List<String>> rows) {
    final numericCols = <int>[];
    final colCount =
        rows.map((r) => r.length).fold<int>(0, (a, b) => a > b ? a : b);
    for (var c = 0; c < colCount; c++) {
      final values = rows
          .map((r) => c < r.length ? r[c] : '')
          .where((v) => v.isNotEmpty)
          .toList();
      if (values.isEmpty) continue;
      final numericCount = values.where(_isNumericToken).length;
      if (numericCount >= (values.length / 2).ceil() && numericCount >= 2) {
        numericCols.add(c);
      }
    }

    // Need two equal blocks, at least 2×2 each.
    if (numericCols.length < 4 || numericCols.length.isOdd) return null;
    final mid = numericCols.length ~/ 2;
    final aCols = numericCols.sublist(0, mid);
    final bCols = numericCols.sublist(mid);
    final a = _extractMatrix(rows, aCols);
    final b = _extractMatrix(rows, bCols);
    if (a == null || b == null) return null;
    if (a.first.length != b.first.length) return null;

    // Only treat as dual when the joined width would look like two matrices
    // (typical exam layout), not a single wide matrix of odd structure.
    final hasAbHint = rows.any(
      (r) => r.any(
        (c) =>
            RegExp(r'[AB]\s*=', caseSensitive: false).hasMatch(c) ||
            c.contains('),') ||
            c.contains(',B'),
      ),
    );
    if (!hasAbHint && numericCols.length < 6) return null;

    _log.info(
      'even-split dual OK cols=$numericCols → A=${a.length}x${a.first.length} '
      'B=${b.length}x${b.first.length} hint=$hasAbHint',
    );
    return '\n\$\$A = ${_toPmatrix(a)}, \\quad B = ${_toPmatrix(b)}\$\$\n';
  }

  static String? _trySingleMatrix(List<List<String>> rows) {
    final cleaned = <List<String>>[];
    for (final row in rows) {
      final cells = <String>[];
      for (var cell in row) {
        cell = cell.replaceAll(RegExp(r'[()]'), '').trim();
        if (cell.isEmpty) continue;
        if (_isNumericToken(cell)) {
          cells.add(_normalizeNumber(cell));
        }
      }
      if (cells.isNotEmpty) cleaned.add(cells);
    }
    if (cleaned.length < 2) return null;
    final width = cleaned.map((r) => r.length).reduce((a, b) => a < b ? a : b);
    if (width < 2) return null;

    // Refuse to emit one wide matrix that is almost certainly A|B side-by-side.
    if (width >= 6 && width.isEven) {
      final half = width ~/ 2;
      final a = cleaned.map((r) => r.take(half).toList()).toList();
      final b = cleaned.map((r) => r.skip(half).take(half).toList()).toList();
      if (b.every((r) => r.length == half)) {
        _log.info('single-path redirected to dual split width=$width');
        return '\n\$\$A = ${_toPmatrix(a)}, \\quad B = ${_toPmatrix(b)}\$\$\n';
      }
    }

    final matrix =
        cleaned.map((r) => r.take(width).toList()).toList(growable: false);
    _log.info('single matrix ${matrix.length}x$width');
    return '\n\$\$${_toPmatrix(matrix)}\$\$\n';
  }

  static List<List<String>>? _parsePlainMatrixBody(String body) {
    final lines = body
        .split(RegExp(r'[\n\r]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final rows = <List<String>>[];
    for (final line in lines) {
      final parts = line
          .split(RegExp(r'[\s,;]+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .where(_isNumericToken)
          .map(_normalizeNumber)
          .toList();
      if (parts.isNotEmpty) rows.add(parts);
    }
    if (rows.length < 2) return null;
    final width = rows.map((r) => r.length).reduce((a, b) => a < b ? a : b);
    if (width < 2) return null;
    return rows.map((r) => r.take(width).toList()).toList();
  }

  static List<List<String>>? _extractMatrix(
    List<List<String>> rows,
    List<int> cols,
  ) {
    final matrix = <List<String>>[];
    for (final row in rows) {
      final values = <String>[];
      for (final c in cols) {
        final raw = c < row.length ? row[c] : '';
        final token = raw.replaceAll(RegExp(r'[()]'), '').trim();
        if (_isNumericToken(token)) {
          values.add(_normalizeNumber(token));
        } else if (token.isEmpty) {
          // skip empty
        } else {
          // Label / noise in this column for this row — skip whole row.
          values.clear();
          break;
        }
      }
      if (values.length == cols.length) {
        matrix.add(values);
      }
    }
    if (matrix.length < 2) return null;
    return matrix;
  }

  static bool _isNumericToken(String s) {
    final t = s.replaceAll(RegExp(r'[()]'), '').trim();
    if (t.isEmpty) return false;
    return RegExp(r'^-?\d+(?:[.,]\d+)?$').hasMatch(t);
  }

  static String _normalizeNumber(String s) {
    return s.replaceAll(RegExp(r'[()]'), '').trim().replaceAll(',', '.');
  }

  static String _toPmatrix(List<List<String>> matrix) {
    final body = matrix.map((r) => r.join(' & ')).join(r' \\ ');
    return '\\begin{pmatrix}$body\\end{pmatrix}';
  }
}
