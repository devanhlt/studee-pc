import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studee_pc/app/theme/app_window_size.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:window_manager/window_manager.dart';

/// Restores/persists overlay window position (no global OS shortcuts).
class DesktopBootstrap with WindowListener {
  DesktopBootstrap();

  final AppLogger _log = AppLogger('DesktopBootstrap');
  SharedPreferences? _prefs;

  // v3 keys discard previously saved wide window bounds (phone-width lock).
  static const _posXKey = 'overlay_window_x_v3';
  static const _posYKey = 'overlay_window_y_v3';
  static const _posHKey = 'overlay_window_h_v3';

  Future<void> start() async {
    if (!_isDesktop) return;

    _prefs = await SharedPreferences.getInstance();
    await _restoreWindowBounds();
    windowManager.addListener(this);
  }

  Future<void> stop() async {
    if (!_isDesktop) return;
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
      // Width is fixed to phoneWidth — only persist height + position.
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
      final h = prefs.getDouble(_posHKey);

      await windowManager.setMinimumSize(AppWindowSize.minimum);
      await windowManager.setMaximumSize(AppWindowSize.maximum);

      if (x == null || y == null) {
        final size = await _clampedSize(AppWindowSize.preferredHeight);
        await windowManager.setSize(size);
        return;
      }

      final size = await _clampedSize(h ?? AppWindowSize.fallbackHeight);
      await windowManager.setBounds(
        Rect.fromLTWH(x, y, size.width, size.height),
      );
    } on Object catch (e) {
      _log.warning('restoreWindowBounds failed: ${e.runtimeType}');
    }
  }

  Future<Size> _clampedSize(double preferredHeight) async {
    var maxH = 4000.0;
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final visible = display.visibleSize ?? display.size;
      maxH = (visible.height - 80).clamp(AppWindowSize.minHeight, 4000);
    } on Object {
      // Fall through with default max.
    }
    final height = preferredHeight
        .clamp(AppWindowSize.minHeight, maxH)
        .toDouble();
    return Size(AppWindowSize.phoneWidth, height);
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
