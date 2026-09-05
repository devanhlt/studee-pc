import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studee_pc/app/theme/app_window_size.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:window_manager/window_manager.dart';

/// Restores/persists overlay window position (no global OS shortcuts).
class DesktopBootstrap with WindowListener {
  DesktopBootstrap();

  final AppLogger _log = AppLogger('DesktopBootstrap');
  SharedPreferences? _prefs;

  // v2 keys discard previously saved large window bounds.
  static const _posXKey = 'overlay_window_x_v2';
  static const _posYKey = 'overlay_window_y_v2';
  static const _posWKey = 'overlay_window_w_v2';
  static const _posHKey = 'overlay_window_h_v2';

  Future<void> start() async {
    if (!_isDesktop) return;

    _prefs = await SharedPreferences.getInstance();
    await _restoreWindowBounds();
    windowManager.addListener(this);
  }

  Future<void> stop() async {
    windowManager.removeListener(this);
    await persistWindowBounds();
  }

  Future<void> persistWindowBounds() async {
    if (!_isDesktop) return;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final bounds = await windowManager.getBounds();
      await prefs.setDouble(_posXKey, bounds.left);
      await prefs.setDouble(_posYKey, bounds.top);
      await prefs.setDouble(_posWKey, bounds.width);
      await prefs.setDouble(_posHKey, bounds.height);
    } on Object catch (e) {
      _log.warning('persistWindowBounds failed: ${e.runtimeType}');
    }
  }

  Future<void> _restoreWindowBounds() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final x = prefs.getDouble(_posXKey);
      final y = prefs.getDouble(_posYKey);
      final w = prefs.getDouble(_posWKey);
      final h = prefs.getDouble(_posHKey);
      if (x == null || y == null) {
        await windowManager.setSize(AppWindowSize.initial);
        await windowManager.setMinimumSize(AppWindowSize.minimum);
        return;
      }
      final width = (w ?? AppWindowSize.fallbackWidth)
          .clamp(AppWindowSize.minimum.width, double.infinity);
      final height = (h ?? AppWindowSize.fallbackHeight)
          .clamp(AppWindowSize.minimum.height, double.infinity);
      await windowManager.setMinimumSize(AppWindowSize.minimum);
      await windowManager.setBounds(
        Rect.fromLTWH(x, y, width.toDouble(), height.toDouble()),
      );
    } on Object catch (e) {
      _log.warning('restoreWindowBounds failed: ${e.runtimeType}');
    }
  }

  @override
  void onWindowMoved() {
    unawaited(persistWindowBounds());
  }

  @override
  void onWindowResized() {
    unawaited(persistWindowBounds());
  }

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
