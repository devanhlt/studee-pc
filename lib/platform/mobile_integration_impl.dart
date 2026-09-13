import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';

/// Mobile adapter: camera + gallery via [ImagePicker]; no overlay/hotkeys/
/// screen capture.
class MobileIntegrationImpl implements PlatformIntegration {
  MobileIntegrationImpl({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final AppLogger _log = AppLogger('MobileIntegration');
  final ImagePicker _picker;
  final StreamController<DesktopShortcutEvent> _shortcutController =
      StreamController<DesktopShortcutEvent>.broadcast();

  void dispose() {
    unawaited(_shortcutController.close());
  }

  @override
  bool get supportsScreenCapture => false;

  @override
  bool get supportsCamera => true;

  @override
  bool get supportsOverlay => false;

  @override
  Stream<DesktopShortcutEvent> get shortcutEvents => _shortcutController.stream;

  @override
  Future<void> setAlwaysOnTop(bool enabled) async {}

  @override
  Future<void> setClickThrough(bool enabled) async {}

  @override
  Future<void> showOverlay() async {}

  @override
  Future<void> hideOverlay() async {}

  @override
  Future<void> openScreenCaptureSettings() async {}

  @override
  Future<bool> isScreenCaptureAllowed() async => true;

  @override
  Future<void> resetAndRequestScreenCaptureAccess() async {}

  @override
  Future<void> registerGlobalShortcut(ShortcutDefinition shortcut) async {}

  @override
  Future<CapturedImage?> captureRegion() async {
    // Mobile has no OS region screen capture.
    return null;
  }

  @override
  Future<CapturedImage?> captureFromCamera() =>
      _pick(ImageSource.camera, logLabel: 'camera');

  @override
  Future<CapturedImage?> pickImage() =>
      _pick(ImageSource.gallery, logLabel: 'gallery');

  Future<CapturedImage?> _pick(
    ImageSource source, {
    required String logLabel,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw const ValidationFailure(
          userMessage: 'Ảnh không có nội dung. Chọn hoặc chụp lại nhé.',
          code: 'image_empty',
        );
      }

      final name = picked.name.toLowerCase();
      final path = picked.path.toLowerCase();
      final mime = name.endsWith('.png') || path.endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      return CapturedImage(
        bytes: Uint8List.fromList(bytes),
        width: 0,
        height: 0,
        mimeType: mime,
      );
    } on AppFailure {
      rethrow;
    } on PlatformException catch (e) {
      _log.warning('$logLabel pick PlatformException: ${e.code}');
      final denied = e.code.toLowerCase().contains('permission') ||
          (e.message?.toLowerCase().contains('permission') ?? false) ||
          e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied';
      throw ValidationFailure(
        userMessage: denied
            ? (source == ImageSource.camera
                ? 'Chưa có quyền Camera. Mở Cài đặt hệ thống để cấp quyền nhé.'
                : 'Chưa có quyền Ảnh. Mở Cài đặt hệ thống để cấp quyền nhé.')
            : (source == ImageSource.camera
                ? 'Không mở được camera. Thử lại nhé.'
                : 'Không chọn được ảnh. Thử lại nhé.'),
        code: denied ? 'media_permission_denied' : 'media_pick_failed',
        details: e.code,
      );
    } on Object catch (e) {
      _log.warning('$logLabel pick failed: ${e.runtimeType}');
      throw ValidationFailure(
        userMessage: source == ImageSource.camera
            ? 'Không mở được camera. Thử lại nhé.'
            : 'Không chọn được ảnh. Thử lại nhé.',
        code: 'media_pick_failed',
        details: e.runtimeType.toString(),
      );
    }
  }
}
