import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:studee_pc/app/app.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/platform/desktop_window_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.initialize(
    level: kDebugMode ? Level.FINE : Level.INFO,
  );

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await bootstrapDesktopWindow();
  }

  runApp(
    const ProviderScope(
      child: StudyOverlayApp(),
    ),
  );
}
