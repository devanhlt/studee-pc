import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Opens a modal camera preview and returns captured JPEG bytes, or null if cancelled.
Future<Uint8List?> showCameraCaptureDialog(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _CameraCaptureDialog(),
  );
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog();

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  CameraController? _controller;
  String? _error;
  bool _initializing = true;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'Không tìm thấy camera trên máy này.';
        });
        return;
      }

      final preferred = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        preferred,
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
      setState(() {
        _initializing = false;
        _error = e.description?.trim().isNotEmpty == true
            ? e.description!
            : (Platform.isWindows
                ? 'Không mở được camera. Kiểm tra quyền Camera trong Cài đặt Windows (Quyền riêng tư).'
                : 'Không mở được camera. Kiểm tra quyền truy cập trong Cài đặt hệ thống.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Không mở được camera: $e';
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(Uint8List.fromList(bytes));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'Chụp ảnh thất bại: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Camera',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _capturing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Center(child: _buildBody(scheme)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _capturing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: (!_initializing &&
                            _error == null &&
                            _controller != null &&
                            !_capturing)
                        ? _takePicture
                        : null,
                    icon: _capturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_capturing ? 'Đang chụp…' : 'Chụp ảnh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_initializing) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onInverseSurface),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }
}
