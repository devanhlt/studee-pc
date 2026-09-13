import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/router.dart';
import 'package:studee_pc/app/theme/app_theme.dart';

/// Root widget: [ProviderScope] + Material 3 dark app with Vietnamese locale.
class StudyOverlayApp extends ConsumerStatefulWidget {
  const StudyOverlayApp({super.key});

  @override
  ConsumerState<StudyOverlayApp> createState() => _StudyOverlayAppState();
}

class _StudyOverlayAppState extends ConsumerState<StudyOverlayApp> {
  var _bootstrapped = false;

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped || !_isDesktop) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDesktop());
  }

  Future<void> _startDesktop() async {
    await ref.read(desktopBootstrapProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Studee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: const Locale('vi'),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
