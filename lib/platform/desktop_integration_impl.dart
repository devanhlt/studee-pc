import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop overlay and capture adapter.
///
/// Uses [window_manager] for always-on-top and [screen_capturer] for region
/// capture. Global OS shortcuts are disabled.
class DesktopIntegrationImpl implements PlatformIntegration {
  DesktopIntegrationImpl();

  final AppLogger _log = AppLogger('DesktopIntegration');
  final StreamController<DesktopShortcutEvent> _shortcutController =
      StreamController<DesktopShortcutEvent>.broadcast();

  static const String _screenCaptureHelp =
      'macOS vẫn báo “đã cấp quyền” nhưng bản app hiện tại không dùng được '
      '(chữ ký cũ / Debug vs DMG). Vào Cài đặt → Ghi màn hình → nút '
      '“Đặt lại quyền Ghi màn hình”, hoặc chạy '
      './scripts/reset_screen_capture_permission.sh — rồi thoát hẳn app và mở lại.';

  static const List<String> _screenCaptureBundleIds = [
    'com.studee.studeePc',
    'com.studee.studeePc.debug',
  ];

  @override
  bool get supportsScreenCapture => true;

  @override
  bool get supportsCamera => false;

  @override
  bool get supportsOverlay => true;

  @override
  Stream<DesktopShortcutEvent> get shortcutEvents => _shortcutController.stream;

  @override
  Future<void> setAlwaysOnTop(bool enabled) async {
    if (!_isDesktop) return;
    try {
      await windowManager.setAlwaysOnTop(enabled);
    } on Object catch (e) {
      _log.warning('setAlwaysOnTop failed: ${e.runtimeType}');
    }
  }

  @override
  Future<void> setClickThrough(bool enabled) async {
    if (!_isDesktop) return;
    try {
      await windowManager.setIgnoreMouseEvents(enabled, forward: true);
    } on Object catch (e) {
      _log.warning('setClickThrough failed: ${e.runtimeType}');
    }
  }

  @override
  Future<void> showOverlay() async {
    if (!_isDesktop) return;
    try {
      await windowManager.show();
      await windowManager.focus();
    } on Object catch (e) {
      _log.warning('showOverlay failed: ${e.runtimeType}');
    }
  }

  @override
  Future<void> hideOverlay() async {
    if (!_isDesktop) return;
    try {
      await windowManager.hide();
    } on Object catch (e) {
      _log.warning('hideOverlay failed: ${e.runtimeType}');
    }
  }

  @override
  Future<void> openScreenCaptureSettings() async {
    if (Platform.isMacOS) {
      try {
        await ScreenCapturer.instance.requestAccess(onlyOpenPrefPane: true);
      } on Object catch (e) {
        _log.warning('openScreenCaptureSettings failed: ${e.runtimeType}');
      }
      return;
    }
    if (Platform.isWindows) {
      try {
        await Process.start(
          'explorer.exe',
          ['ms-settings:privacy'],
          mode: ProcessStartMode.detached,
        );
      } on Object catch (e) {
        _log.warning('open Windows privacy settings failed: ${e.runtimeType}');
      }
    }
  }

  @override
  Future<bool> isScreenCaptureAllowed() async {
    if (!Platform.isMacOS) return true;
    try {
      return await ScreenCapturer.instance.isAccessAllowed();
    } on Object catch (e) {
      _log.warning('isScreenCaptureAllowed failed: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<void> resetAndRequestScreenCaptureAccess() async {
    if (!Platform.isMacOS) {
      await openScreenCaptureSettings();
      return;
    }
    for (final id in _screenCaptureBundleIds) {
      try {
        final result = await Process.run('tccutil', [
          'reset',
          'ScreenCapture',
          id,
        ]);
        _log.info(
          'tccutil reset ScreenCapture $id → exit=${result.exitCode}',
        );
      } on Object catch (e) {
        _log.warning('tccutil reset $id failed: ${e.runtimeType}');
      }
    }
    try {
      await ScreenCapturer.instance.requestAccess();
    } on Object catch (e) {
      _log.warning('requestAccess after reset failed: ${e.runtimeType}');
    }
    await openScreenCaptureSettings();
  }

  @override
  Future<CapturedImage?> captureRegion() async {
    if (!_isDesktop) return null;
    try {
      if (Platform.isMacOS) {
        final allowed = await ScreenCapturer.instance.isAccessAllowed();
        if (!allowed) {
          // Do not only open Settings — the toggle often looks "on" for a
          // stale signature while CGPreflight is still false.
          throw const ScreenCaptureFailure(
            userMessage:
                'Studee chưa có quyền Ghi màn hình hiệu lực. Nếu Cài đặt '
                'đã hiện “bật”, hãy dùng Cài đặt trong app → '
                '“Đặt lại quyền Ghi màn hình”, thoát hẳn app rồi mở lại.',
            code: 'screen_capture_stale',
          );
        }
      }

      final tempDir = await getTemporaryDirectory();
      final imagePath = p.join(
        tempDir.path,
        'studee_capture_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final data = await ScreenCapturer.instance.capture(
        mode: CaptureMode.region,
        imagePath: imagePath,
        copyToClipboard: true,
        silent: true,
      );
      if (data == null || data.imageBytes == null) {
        // User cancel OR stale TCC grant from a different binary (debug vs DMG).
        if (Platform.isMacOS) {
          final stillAllowed = await ScreenCapturer.instance.isAccessAllowed();
          if (!stillAllowed) {
            throw const ScreenCaptureFailure(
              userMessage:
                  'Quyền Ghi màn hình không còn hiệu lực. Vào Cài đặt → '
                  '“Đặt lại quyền Ghi màn hình”, thoát app rồi mở lại.',
              code: 'screen_capture_stale',
            );
          }
          _log.warning(
            'captureRegion returned empty while access allowed — '
            'possible TCC conflict or user cancel',
          );
        }
        return null;
      }

      return CapturedImage(
        bytes: data.imageBytes!,
        width: data.imageWidth ?? 0,
        height: data.imageHeight ?? 0,
      );
    } on ScreenCaptureFailure {
      rethrow;
    } on Object catch (e) {
      _log.warning('captureRegion failed: ${e.runtimeType}');
      if (Platform.isMacOS) {
        throw ScreenCaptureFailure(
          userMessage: _screenCaptureHelp,
          details: e.runtimeType.toString(),
        );
      }
      if (Platform.isWindows) {
        throw ScreenCaptureFailure(
          userMessage:
              'Không chụp được vùng màn hình. Kiểm tra Quyền riêng tư '
              'Windows (Cài đặt hệ thống → Quyền riêng tư), rồi thử lại.',
          details: e.runtimeType.toString(),
          code: 'screen_capture_windows',
        );
      }
      return null;
    }
  }

  @override
  Future<CapturedImage?> captureFromCamera() async {
    // Desktop does not offer live camera capture.
    return null;
  }

  @override
  Future<CapturedImage?> pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      final files = result?.files;
      if (files == null || files.isEmpty) return null;
      final file = files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return null;

      final name = file.name.toLowerCase();
      final mime = name.endsWith('.jpg') || name.endsWith('.jpeg')
          ? 'image/jpeg'
          : 'image/png';

      return CapturedImage(
        bytes: Uint8List.fromList(bytes),
        width: 0,
        height: 0,
        mimeType: mime,
      );
    } on Object catch (e) {
      _log.warning('pickImage failed: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<void> registerGlobalShortcut(ShortcutDefinition shortcut) async {
    // Global OS shortcuts are disabled.
    return;
  }

  Future<void> dispose() async {
    try {
      await hotKeyManager.unregisterAll();
    } on Object {
      // Best-effort cleanup.
    }
    await _shortcutController.close();
  }

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
