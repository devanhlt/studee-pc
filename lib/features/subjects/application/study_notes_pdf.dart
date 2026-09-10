import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/features/subjects/application/study_notes_math_raster.dart';

/// Export format for "Xuất tài liệu".
enum StudyNotesExportFormat {
  markdown,
  pdf;

  String get labelVi => switch (this) {
        StudyNotesExportFormat.markdown => 'Markdown (.md)',
        StudyNotesExportFormat.pdf => 'PDF (.pdf)',
      };

  String get fileExtension => switch (this) {
        StudyNotesExportFormat.markdown => 'md',
        StudyNotesExportFormat.pdf => 'pdf',
      };
}

/// Renders study-notes Markdown into a printable PDF.
///
/// Uses Roboto for body text and rasters LaTeX formulas
/// (`$…$`, `$$…$$`, `\(...\)`, `\[…\]`) via flutter_math_fork.
abstract final class StudyNotesPdf {
  static const _regularAsset = 'assets/fonts/Roboto-Regular.ttf';
  static const _boldAsset = 'assets/fonts/Roboto-Bold.ttf';

  /// Usable content width on A4 with 40pt margins.
  static final double _contentWidth = PdfPageFormat.a4.width - 80;

  /// Builds PDF bytes from [markdown] produced by [buildStudyNotesMarkdown].
  static Future<Uint8List> buildBytes(String markdown) async {
    final regularData = await rootBundle.load(_regularAsset);
    final boldData = await rootBundle.load(_boldAsset);
    final base = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);

    final theme = pw.ThemeData.withFont(base: base, bold: bold);
    final prepared = StudyMarkdown.prepareForRender(markdown);
    final blocks = _parseBlocks(prepared);

    // Pre-render every unique formula at readable size.
    final mathCache = <String, pw.MemoryImage?>{};
    for (final block in blocks) {
      for (final seg in block.segments) {
        if (seg is! _MathSeg) continue;
        final key = '${seg.display}|${seg.tex}';
        if (mathCache.containsKey(key)) continue;
        final png = await StudyNotesMathRaster.toPng(
          seg.tex,
          display: seg.display,
          fontSize: seg.display ? 26 : 20,
          pixelRatio: 3,
        );
        mathCache[key] = png == null ? null : pw.MemoryImage(png);
      }
    }

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          for (final block in blocks) ...[
            _blockWidget(block, mathCache),
            pw.SizedBox(height: block.spacingAfter),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _blockWidget(
    _PdfBlock block,
    Map<String, pw.MemoryImage?> mathCache,
  ) {
    final body = _segmentsWidget(
      block.segments,
      fontSize: block.fontSize,
      boldDefault: block.boldDefault,
      mathCache: mathCache,
    );

    switch (block.kind) {
      case _PdfBlockKind.h1:
      case _PdfBlockKind.h2:
      case _PdfBlockKind.h3:
      case _PdfBlockKind.paragraph:
        return body;
      case _PdfBlockKind.bullet:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(fontSize: block.fontSize)),
              pw.Expanded(child: body),
            ],
          ),
        );
      case _PdfBlockKind.displayMath:
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: body,
        );
      case _PdfBlockKind.code:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            block.segments
                .whereType<_TextSeg>()
                .map((s) => s.text)
                .join(),
            style: pw.TextStyle(
              fontSize: 9.5,
              font: pw.Font.courier(),
              lineSpacing: 1.5,
              color: PdfColors.grey900,
            ),
          ),
        );
    }
  }

  static pw.Widget _segmentsWidget(
    List<_Seg> segments, {
    required double fontSize,
    required bool boldDefault,
    required Map<String, pw.MemoryImage?> mathCache,
  }) {
    if (segments.isEmpty) {
      return pw.SizedBox();
    }

    // Pure text → RichText (better wrapping).
    if (segments.every((s) => s is _TextSeg)) {
      return pw.RichText(
        text: pw.TextSpan(
          children: [
            for (final s in segments.cast<_TextSeg>())
              pw.TextSpan(
                text: s.text,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: (boldDefault || s.bold)
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
          ],
        ),
      );
    }

    // Mixed text + math → Wrap so formulas sit on the line.
    return pw.Wrap(
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      children: [
        for (final seg in segments) _segWidget(seg, fontSize, boldDefault, mathCache),
      ],
    );
  }

  static pw.Widget _segWidget(
    _Seg seg,
    double fontSize,
    bool boldDefault,
    Map<String, pw.MemoryImage?> mathCache,
  ) {
    if (seg is _TextSeg) {
      if (seg.text.isEmpty) return pw.SizedBox();
      return pw.Text(
        seg.text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: (boldDefault || seg.bold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      );
    }
    if (seg is _MathSeg) {
      final key = '${seg.display}|${seg.tex}';
      final image = mathCache[key];
      if (image != null) {
        // Size by natural aspect ratio — do NOT force a tiny height+full width
        // (BoxFit.contain would shrink formulas to fit the short edge).
        final pxW = (image.width ?? 120).toDouble();
        final pxH = (image.height ?? 40).toDouble();
        final targetH = seg.display ? 36.0 : 24.0;
        var drawH = targetH;
        var drawW = drawH * (pxW / pxH);
        if (drawW > _contentWidth) {
          drawW = _contentWidth;
          drawH = drawW * (pxH / pxW);
        }
        // Cap extreme tall display formulas but keep them readable.
        final maxH = seg.display ? 120.0 : 40.0;
        if (drawH > maxH) {
          drawH = maxH;
          drawW = drawH * (pxW / pxH);
        }
        return pw.Container(
          margin: pw.EdgeInsets.symmetric(
            horizontal: 2,
            vertical: seg.display ? 6 : 1,
          ),
          child: pw.Image(
            image,
            width: drawW,
            height: drawH,
            fit: pw.BoxFit.fill,
            alignment: pw.Alignment.centerLeft,
          ),
        );
      }
      // Fallback: show TeX source in monospace-like text.
      final fallback = seg.display ? '\$\$${seg.tex}\$\$' : '\$${seg.tex}\$';
      return pw.Text(
        fallback,
        style: pw.TextStyle(
          fontSize: fontSize * 0.95,
          color: PdfColors.grey700,
          fontWeight: pw.FontWeight.normal,
        ),
      );
    }
    return pw.SizedBox();
  }

  static List<_PdfBlock> _parseBlocks(String markdown) {
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    final out = <_PdfBlock>[];
    final para = StringBuffer();
    var inCode = false;
    final codeBuf = StringBuffer();

    void flushPara({bool bullet = false}) {
      final t = para.toString().trim();
      para.clear();
      if (t.isEmpty) return;
      final segs = _tokenizeInline(t);
      // If the whole paragraph is one display math, promote it.
      if (segs.length == 1 && segs.first is _MathSeg && (segs.first as _MathSeg).display) {
        out.add(
          _PdfBlock(
            _PdfBlockKind.displayMath,
            segs,
            fontSize: 12,
            spacingAfter: 8,
          ),
        );
        return;
      }
      out.add(
        _PdfBlock(
          bullet ? _PdfBlockKind.bullet : _PdfBlockKind.paragraph,
          segs,
          fontSize: 11,
          spacingAfter: bullet ? 3 : 6,
        ),
      );
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      // Fenced code blocks: ```lang ... ```
      if (!inCode && trimmed.startsWith('```')) {
        flushPara();
        inCode = true;
        codeBuf.clear();
        continue;
      }
      if (inCode) {
        if (trimmed.startsWith('```')) {
          inCode = false;
          final code = codeBuf.toString().trimRight();
          if (code.isNotEmpty) {
            out.add(
              _PdfBlock(
                _PdfBlockKind.code,
                [_TextSeg(code)],
                fontSize: 9.5,
                spacingAfter: 8,
              ),
            );
          }
          continue;
        }
        if (codeBuf.isNotEmpty) codeBuf.writeln();
        codeBuf.write(line);
        continue;
      }

      if (trimmed.isEmpty) {
        flushPara();
        continue;
      }

      // Standalone display math line.
      final displayOnly = RegExp(r'^\$\$([\s\S]+?)\$\$\s*$').firstMatch(trimmed) ??
          RegExp(r'^\\\[([\s\S]+?)\\\]\s*$').firstMatch(trimmed);
      if (displayOnly != null) {
        flushPara();
        final tex = StudyMarkdown.normalizeTex(displayOnly.group(1)!);
        out.add(
          _PdfBlock(
            _PdfBlockKind.displayMath,
            [_MathSeg(tex, display: true)],
            fontSize: 12,
            spacingAfter: 8,
          ),
        );
        continue;
      }

      if (trimmed.startsWith('# ')) {
        flushPara();
        out.add(
          _PdfBlock(
            _PdfBlockKind.h1,
            _tokenizeInline(trimmed.substring(2).trim()),
            fontSize: 20,
            boldDefault: true,
            spacingAfter: 10,
          ),
        );
        continue;
      }
      if (trimmed.startsWith('## ')) {
        flushPara();
        out.add(
          _PdfBlock(
            _PdfBlockKind.h2,
            _tokenizeInline(trimmed.substring(3).trim()),
            fontSize: 15,
            boldDefault: true,
            spacingAfter: 8,
          ),
        );
        continue;
      }
      if (trimmed.startsWith('### ')) {
        flushPara();
        out.add(
          _PdfBlock(
            _PdfBlockKind.h3,
            _tokenizeInline(trimmed.substring(4).trim()),
            fontSize: 13,
            boldDefault: true,
            spacingAfter: 6,
          ),
        );
        continue;
      }
      final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        flushPara();
        para.write(bullet.group(1)!.trim());
        flushPara(bullet: true);
        continue;
      }
      if (para.isNotEmpty) para.write(' ');
      para.write(trimmed);
    }
    flushPara();
    if (inCode && codeBuf.isNotEmpty) {
      out.add(
        _PdfBlock(
          _PdfBlockKind.code,
          [_TextSeg(codeBuf.toString().trimRight())],
          fontSize: 9.5,
          spacingAfter: 8,
        ),
      );
    }
    return out;
  }

  /// Split into text (with **bold**) and math segments.
  static List<_Seg> _tokenizeInline(String input) {
    final segs = <_Seg>[];
    // Display / inline math: $$ $$ then \[ \] then \( \) then $ $
    final re = RegExp(
      r'\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\((.+?)\\\)|\$([^\$]+?)\$',
      multiLine: true,
    );
    var start = 0;
    for (final m in re.allMatches(input)) {
      if (m.start > start) {
        segs.addAll(_tokenizeBold(input.substring(start, m.start)));
      }
      if (m.group(1) != null) {
        segs.add(_MathSeg(StudyMarkdown.normalizeTex(m.group(1)!), display: true));
      } else if (m.group(2) != null) {
        segs.add(_MathSeg(StudyMarkdown.normalizeTex(m.group(2)!), display: true));
      } else if (m.group(3) != null) {
        segs.add(_MathSeg(StudyMarkdown.normalizeTex(m.group(3)!), display: false));
      } else if (m.group(4) != null) {
        segs.add(_MathSeg(StudyMarkdown.normalizeTex(m.group(4)!), display: false));
      }
      start = m.end;
    }
    if (start < input.length) {
      segs.addAll(_tokenizeBold(input.substring(start)));
    }
    return segs;
  }

  static List<_Seg> _tokenizeBold(String input) {
    if (input.isEmpty) return const [];
    final out = <_Seg>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;
    for (final m in re.allMatches(input)) {
      if (m.start > start) {
        out.add(_TextSeg(input.substring(start, m.start)));
      }
      out.add(_TextSeg(m.group(1)!, bold: true));
      start = m.end;
    }
    if (start < input.length) {
      out.add(_TextSeg(input.substring(start)));
    }
    return out;
  }
}

enum _PdfBlockKind { h1, h2, h3, bullet, paragraph, displayMath, code }

class _PdfBlock {
  const _PdfBlock(
    this.kind,
    this.segments, {
    required this.fontSize,
    this.boldDefault = false,
    this.spacingAfter = 6,
  });

  final _PdfBlockKind kind;
  final List<_Seg> segments;
  final double fontSize;
  final bool boldDefault;
  final double spacingAfter;
}

sealed class _Seg {}

class _TextSeg extends _Seg {
  _TextSeg(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _MathSeg extends _Seg {
  _MathSeg(this.tex, {required this.display});
  final String tex;
  final bool display;
}
