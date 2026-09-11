import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:studee_pc/app/theme/app_window_size.dart';
import 'package:window_manager/window_manager.dart';

/// Initializes [window_manager] + clears global hotkeys (desktop only).
///
/// Kept in a separate library so mobile entrypoints do not need to touch
/// desktop-only plugin APIs beyond transitive deps.
Future<void> bootstrapDesktopWindow() async {
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: AppWindowSize.initial,
    minimumSize: AppWindowSize.minimum,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Studee',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setSize(AppWindowSize.initial);
    await windowManager.setMinimumSize(AppWindowSize.minimum);
    await windowManager.show();
    await windowManager.focus();
  });

  try {
    await hotKeyManager.unregisterAll();
  } on Object {
    // Hotkeys may be unavailable in some desktop environments.
  }
}
