import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';

/// Live camera capture, then crop the frozen photo with Done / Retake.
class ScanQuestionScreen extends StatefulWidget {
  const ScanQuestionScreen({super.key});

  /// Opens fullscreen. Returns cropped capture, or null if cancelled.
  static Future<CapturedImage?> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<CapturedImage>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ScanQuestionScreen(),
      ),
    );
  }

  @override
  State<ScanQuestionScreen> createState() => _ScanQuestionScreenState();
}

class _ScanQuestionScreenState extends State<ScanQuestionScreen> {
  CameraController? _controller;
  String? _error;
  bool _initializing = true;
  bool _capturing = false;
  bool _finishing = false;

  /// Full captured JPEG (orientation-baked) while in crop review.
  Uint8List? _capturedBytes;

  /// Selection in viewport coordinates (same space as the preview stack).
  Rect _selection = Rect.zero;
  Size _viewport = Size.zero;

  static const _minSelection = 80.0;

  bool get _reviewing => _capturedBytes != null;

  @override
  void initState() {
    super.initState();
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'Không tìm thấy camera trên thiết bị.';
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = (e.code.toLowerCase().contains('access') ||
          e.code.toLowerCase().contains('permission') ||
          e.description?.toLowerCase().contains('permission') == true);
      setState(() {
        _initializing = false;
        _error = denied
            ? 'Chưa có quyền Camera. Mở Cài đặt hệ thống để cấp quyền nhé.'
            : 'Không mở được camera. Thử lại nhé.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Không mở được camera. Thử lại nhé.';
      });
    }
  }

  void _resetSelectionForViewport(Size viewport) {
    _viewport = viewport;
    final w = viewport.width * 0.88;
    final h = math.min(viewport.height * 0.42, w * 0.7);
    _selection = Rect.fromCenter(
      center: Offset(viewport.width / 2, viewport.height * 0.42),
      width: w,
      height: h,
    );
  }

  Rect _clampSelection(Rect rect) {
    var w = rect.width.clamp(_minSelection, _viewport.width);
    var h = rect.height.clamp(_minSelection, _viewport.height);
    var left = rect.left.clamp(0.0, _viewport.width - w);
    var top = rect.top.clamp(0.0, _viewport.height - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  void _onDragSelection(DragUpdateDetails details) {
    setState(() {
      _selection = _clampSelection(_selection.shift(details.delta));
    });
  }

  void _onResizeCorner(_Corner corner, DragUpdateDetails details) {
    setState(() {
      var left = _selection.left;
      var top = _selection.top;
      var right = _selection.right;
      var bottom = _selection.bottom;
      switch (corner) {
        case _Corner.topLeft:
          left += details.delta.dx;
          top += details.delta.dy;
        case _Corner.topRight:
          right += details.delta.dx;
          top += details.delta.dy;
        case _Corner.bottomLeft:
          left += details.delta.dx;
          bottom += details.delta.dy;
        case _Corner.bottomRight:
          right += details.delta.dx;
          bottom += details.delta.dy;
      }
      if (right - left < _minSelection) {
        if (corner == _Corner.topLeft || corner == _Corner.bottomLeft) {
          left = right - _minSelection;
        } else {
          right = left + _minSelection;
        }
      }
      if (bottom - top < _minSelection) {
        if (corner == _Corner.topLeft || corner == _Corner.topRight) {
          top = bottom - _minSelection;
        } else {
          bottom = top + _minSelection;
        }
      }
      _selection = _clampSelection(Rect.fromLTRB(left, top, right, bottom));
    });
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        _reviewing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      try {
        await File(file.path).delete();
      } on Object {
        // Best-effort cleanup.
      }
      if (bytes.isEmpty) {
        throw const ValidationFailure(
          userMessage: 'Ảnh từ camera không có nội dung. Thử lại nhé.',
          code: 'image_empty',
        );
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const ValidationFailure(
          userMessage: 'Không đọc được ảnh. Thử lại nhé.',
          code: 'image_decode_failed',
        );
      }
      final oriented = img.bakeOrientation(decoded);
      final baked = Uint8List.fromList(img.encodeJpg(oriented, quality: 92));
      if (!mounted) return;
      setState(() {
        _capturedBytes = baked;
        _capturing = false;
        _selection = Rect.zero;
        _viewport = Size.zero;
      });
    } on AppFailure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.userMessage)),
      );
      setState(() => _capturing = false);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is CameraException
                ? 'Không chụp được ảnh. Thử lại nhé.'
                : 'Không xử lý được ảnh. Thử lại nhé.',
          ),
        ),
      );
      setState(() => _capturing = false);
    }
  }

  void _retake() {
    setState(() {
      _capturedBytes = null;
      _selection = Rect.zero;
      _viewport = Size.zero;
      _finishing = false;
    });
  }

  Future<void> _done() async {
    final bytes = _capturedBytes;
    if (bytes == null || _selection == Rect.zero || _finishing) return;
    setState(() => _finishing = true);
    try {
      final cropped = _cropToSelection(bytes);
      if (!mounted) return;
      Navigator.of(context).pop(cropped);
    } on AppFailure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.userMessage)),
      );
      setState(() => _finishing = false);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không cắt được ảnh. Thử lại nhé.')),
      );
      setState(() => _finishing = false);
    }
  }

  CapturedImage _cropToSelection(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ValidationFailure(
        userMessage: 'Không đọc được ảnh. Thử lại nhé.',
        code: 'image_decode_failed',
      );
    }
    final mapped = _mapOverlayToImage(
      overlayRect: _selection,
      viewportSize: _viewport,
      imageSize: Size(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      ),
    );
    final x = mapped.left.round().clamp(0, decoded.width - 1);
    final y = mapped.top.round().clamp(0, decoded.height - 1);
    final w = mapped.width.round().clamp(1, decoded.width - x);
    final h = mapped.height.round().clamp(1, decoded.height - y);
    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final out = Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
    if (out.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Ảnh cắt không có nội dung. Thử lại nhé.',
        code: 'crop_empty',
      );
    }
    return CapturedImage(
      bytes: out,
      width: cropped.width,
      height: cropped.height,
      mimeType: 'image/jpeg',
    );
  }

  /// Maps a viewport overlay rect onto the image under BoxFit.cover.
  static Rect _mapOverlayToImage({
    required Rect overlayRect,
    required Size viewportSize,
    required Size imageSize,
  }) {
    final imageAspect = imageSize.width / imageSize.height;
    final viewAspect = viewportSize.width / viewportSize.height;

    late final double displayW;
    late final double displayH;
    late final double offsetX;
    late final double offsetY;
    if (imageAspect > viewAspect) {
      displayH = viewportSize.height;
      displayW = displayH * imageAspect;
      offsetX = (viewportSize.width - displayW) / 2;
      offsetY = 0;
    } else {
      displayW = viewportSize.width;
      displayH = displayW / imageAspect;
      offsetX = 0;
      offsetY = (viewportSize.height - displayH) / 2;
    }

    final scaleX = imageSize.width / displayW;
    final scaleY = imageSize.height / displayH;

    final left =
        ((overlayRect.left - offsetX) * scaleX).clamp(0.0, imageSize.width);
    final top =
        ((overlayRect.top - offsetY) * scaleY).clamp(0.0, imageSize.height);
    final right =
        ((overlayRect.right - offsetX) * scaleX).clamp(0.0, imageSize.width);
    final bottom =
        ((overlayRect.bottom - offsetY) * scaleY).clamp(0.0, imageSize.height);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Widget _buildViewport(Size viewport) {
    if (_reviewing) {
      if (_viewport != viewport || _selection == Rect.zero) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_reviewing) return;
          setState(() => _resetSelectionForViewport(viewport));
        });
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Image.memory(
              _capturedBytes!,
              fit: BoxFit.cover,
              width: viewport.width,
              height: viewport.height,
              gaplessPlayback: true,
            ),
          ),
          if (_selection != Rect.zero) ...[
            CustomPaint(
              painter: _ScanMaskPainter(selection: _selection),
              child: const SizedBox.expand(),
            ),
            Positioned.fromRect(
              rect: _selection,
              child: GestureDetector(
                onPanUpdate: _onDragSelection,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            ..._Corner.values.map((corner) {
              final offset = switch (corner) {
                _Corner.topLeft => _selection.topLeft,
                _Corner.topRight => _selection.topRight,
                _Corner.bottomLeft => _selection.bottomLeft,
                _Corner.bottomRight => _selection.bottomRight,
              };
              return Positioned(
                left: offset.dx - 18,
                top: offset.dy - 18,
                child: GestureDetector(
                  onPanUpdate: (d) => _onResizeCorner(corner, d),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      );
    }

    final controller = _controller!;
    return _CoverCameraPreview(controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = _capturing || _finishing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_error != null)
            _ErrorBody(
              message: _error!,
              onClose: () => Navigator.of(context).pop(),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final viewport =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return _buildViewport(viewport);
              },
            ),
          Positioned(
            top: top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(AppIcons.close, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    _reviewing ? 'Chọn vùng đề bài' : 'Quét câu hỏi',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_controller != null && _error == null)
            Positioned(
              left: 24,
              right: 24,
              bottom: bottom + 28,
              child: _reviewing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kéo khung để chọn vùng đề bài.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy ? null : _retake,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Chụp lại'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: busy || _selection == Rect.zero
                                    ? null
                                    : _done,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _finishing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Xong'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chụp toàn bộ đề bài, rồi chọn vùng cần giải.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: busy ? null : _capture,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 4),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _capturing
                                    ? Colors.white38
                                    : AppColors.accent,
                              ),
                              child: _capturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      AppIcons.cameraFill,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }
    // previewSize is landscape sensor space; swap for portrait display.
    final previewW = previewSize.height;
    final previewH = previewSize.width;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewW,
          height: previewH,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _ScanMaskPainter extends CustomPainter {
  _ScanMaskPainter({required this.selection});

  final Rect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(selection, const Radius.circular(12)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(selection, const Radius.circular(12)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanMaskPainter oldDelegate) =>
      oldDelegate.selection != selection;
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(AppIcons.close, color: Colors.white),
              ),
            ),
            const Spacer(),
            Icon(
              AppIcons.camera,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onClose,
              child: const Text('Đóng'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
