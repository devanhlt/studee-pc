import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logging/logging.dart';
import 'package:studee_pc/app/app.dart';
import 'package:studee_pc/app/theme/app_window_size.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.initialize(
    level: kDebugMode ? Level.FINE : Level.INFO,
  );

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
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

  runApp(
    const ProviderScope(
      child: StudyOverlayApp(),
    ),
  );
}
