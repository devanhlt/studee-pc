import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop overlay, capture, and global-shortcut adapter.
///
/// Uses [window_manager] for always-on-top, [screen_capturer] for region
/// capture, and [hotkey_manager] for global shortcuts. No live camera.
class DesktopIntegrationImpl implements PlatformIntegration {
  DesktopIntegrationImpl();

  final AppLogger _log = AppLogger('DesktopIntegration');
  final StreamController<DesktopShortcutEvent> _shortcutController =
      StreamController<DesktopShortcutEvent>.broadcast();

  final Map<String, HotKey> _registered = {};

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
    if (!_isDesktop) return;

    final existing = _registered.remove(shortcut.id);
    if (existing != null) {
      try {
        await hotKeyManager.unregister(existing);
      } on Object {
        // Ignore unregister failures when rebinding.
      }
    }

    final key = _resolveLogicalKey(shortcut.key);
    if (key == null) {
      _log.warning('Unknown shortcut key id=${shortcut.id}');
      return;
    }

    final modifiers = shortcut.modifiers
        .map(_resolveModifier)
        .whereType<HotKeyModifier>()
        .toList();

    final hotKey = HotKey(
      identifier: shortcut.id,
      key: key,
      modifiers: modifiers.isEmpty ? null : modifiers,
      scope: HotKeyScope.system,
    );

    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) {
          if (!_shortcutController.isClosed) {
            _shortcutController.add(
              DesktopShortcutEvent(
                shortcutId: shortcut.id,
                triggeredAt: DateTime.now().toUtc(),
              ),
            );
          }
        },
      );
      _registered[shortcut.id] = hotKey;
      _log.info('Registered shortcut id=${shortcut.id}');
    } on Object catch (e) {
      _log.warning('registerGlobalShortcut failed: ${e.runtimeType}');
    }
  }

  Future<void> dispose() async {
    for (final hotKey in _registered.values) {
      try {
        await hotKeyManager.unregister(hotKey);
      } on Object {
        // Best-effort cleanup.
      }
    }
    _registered.clear();
    await _shortcutController.close();
  }

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static LogicalKeyboardKey? _resolveLogicalKey(String key) {
    final normalized = key.trim().toLowerCase();
    return switch (normalized) {
      'a' => LogicalKeyboardKey.keyA,
      'b' => LogicalKeyboardKey.keyB,
      'c' => LogicalKeyboardKey.keyC,
      'd' => LogicalKeyboardKey.keyD,
      'e' => LogicalKeyboardKey.keyE,
      'f' => LogicalKeyboardKey.keyF,
      'g' => LogicalKeyboardKey.keyG,
      'h' => LogicalKeyboardKey.keyH,
      'i' => LogicalKeyboardKey.keyI,
      'j' => LogicalKeyboardKey.keyJ,
      'k' => LogicalKeyboardKey.keyK,
      'l' => LogicalKeyboardKey.keyL,
      'm' => LogicalKeyboardKey.keyM,
      'n' => LogicalKeyboardKey.keyN,
      'o' => LogicalKeyboardKey.keyO,
      'p' => LogicalKeyboardKey.keyP,
      'q' => LogicalKeyboardKey.keyQ,
      'r' => LogicalKeyboardKey.keyR,
      's' => LogicalKeyboardKey.keyS,
      't' => LogicalKeyboardKey.keyT,
      'u' => LogicalKeyboardKey.keyU,
      'v' => LogicalKeyboardKey.keyV,
      'w' => LogicalKeyboardKey.keyW,
      'x' => LogicalKeyboardKey.keyX,
      'y' => LogicalKeyboardKey.keyY,
      'z' => LogicalKeyboardKey.keyZ,
      '1' || 'digit1' => LogicalKeyboardKey.digit1,
      '2' || 'digit2' => LogicalKeyboardKey.digit2,
      '3' || 'digit3' => LogicalKeyboardKey.digit3,
      '4' || 'digit4' => LogicalKeyboardKey.digit4,
      '5' || 'digit5' => LogicalKeyboardKey.digit5,
      '6' || 'digit6' => LogicalKeyboardKey.digit6,
      '7' || 'digit7' => LogicalKeyboardKey.digit7,
      '8' || 'digit8' => LogicalKeyboardKey.digit8,
      '9' || 'digit9' => LogicalKeyboardKey.digit9,
      '0' || 'digit0' => LogicalKeyboardKey.digit0,
      'space' => LogicalKeyboardKey.space,
      'enter' || 'return' => LogicalKeyboardKey.enter,
      'escape' || 'esc' => LogicalKeyboardKey.escape,
      'tab' => LogicalKeyboardKey.tab,
      'f1' => LogicalKeyboardKey.f1,
      'f2' => LogicalKeyboardKey.f2,
      'f3' => LogicalKeyboardKey.f3,
      'f4' => LogicalKeyboardKey.f4,
      'f5' => LogicalKeyboardKey.f5,
      'f6' => LogicalKeyboardKey.f6,
      'f7' => LogicalKeyboardKey.f7,
      'f8' => LogicalKeyboardKey.f8,
      'f9' => LogicalKeyboardKey.f9,
      'f10' => LogicalKeyboardKey.f10,
      'f11' => LogicalKeyboardKey.f11,
      'f12' => LogicalKeyboardKey.f12,
      _ => null,
    };
  }

  static HotKeyModifier? _resolveModifier(String name) {
    return switch (name.trim().toLowerCase()) {
      'alt' || 'option' => HotKeyModifier.alt,
      'control' || 'ctrl' => HotKeyModifier.control,
      'shift' => HotKeyModifier.shift,
      'meta' || 'cmd' || 'command' || 'win' || 'windows' => HotKeyModifier.meta,
      'fn' => HotKeyModifier.fn,
      _ => null,
    };
  }
}
