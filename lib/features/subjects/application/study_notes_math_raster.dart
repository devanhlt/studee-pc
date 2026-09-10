import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:screenshot/screenshot.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';

/// Renders LaTeX to PNG for PDF embedding (via flutter_math_fork).
abstract final class StudyNotesMathRaster {
  static final ScreenshotController _controller = ScreenshotController();

  /// Returns PNG bytes, or null if rendering fails.
  static Future<Uint8List?> toPng(
    String rawTex, {
    required bool display,
    double fontSize = 14,
    double pixelRatio = 3,
  }) async {
    final tex = StudyMarkdown.normalizeTex(rawTex);
    if (tex.isEmpty) return null;

    try {
      final bytes = await _controller.captureFromWidget(
        _MathCapture(
          tex: tex,
          display: display,
          fontSize: fontSize,
        ),
        delay: const Duration(milliseconds: 40),
        pixelRatio: pixelRatio,
        targetSize: display ? const Size(1200, 400) : const Size(1200, 160),
      );
      return bytes.isEmpty ? null : bytes;
    } on Object {
      return null;
    }
  }
}

class _MathCapture extends StatelessWidget {
  const _MathCapture({
    required this.tex,
    required this.display,
    required this.fontSize,
  });

  final String tex;
  final bool display;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 500)),
        child: Material(
          color: Colors.white,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: display ? 6 : 2,
                  ),
                  child: Math.tex(
                    tex,
                    mathStyle: display ? MathStyle.display : MathStyle.text,
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    onErrorFallback: (_) => Text(
                      display ? '\$\$$tex\$\$' : '\$$tex\$',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
