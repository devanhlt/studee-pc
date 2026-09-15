import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/theme/app_motion.dart';
import 'package:studee_pc/features/history/presentation/history_list.dart';
import 'package:studee_pc/features/ingestion/presentation/ingestion_screen.dart';
import 'package:studee_pc/features/overlay/presentation/overlay_panel.dart';
import 'package:studee_pc/features/settings/presentation/request_activation_code_screen.dart';
import 'package:studee_pc/features/settings/presentation/settings_screen.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/presentation/subject_detail_screen.dart';
import 'package:studee_pc/features/subjects/presentation/subjects_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool get _isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

CustomTransitionPage<void> _fadeRisePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'subjects',
        pageBuilder: (context, state) => _fadeRisePage(
          key: state.pageKey,
          child: const SubjectsListScreen(),
        ),
      ),
      GoRoute(
        path: '/subjects/:id',
        name: 'subjectDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeRisePage(
            key: state.pageKey,
            child: SubjectDetailScreen(subjectId: id),
          );
        },
        routes: [
          GoRoute(
            path: 'import',
            name: 'import',
            redirect: (context, state) {
              if (!_isDesktop) {
                final id = state.pathParameters['id'];
                return id == null ? '/' : '/subjects/$id';
              }
              return null;
            },
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeRisePage(
                key: state.pageKey,
                child: IngestionScreen(subjectId: id),
              );
            },
          ),
          GoRoute(
            path: 'solve',
            name: 'solve',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeRisePage(
                key: state.pageKey,
                child: SolveScreen(subjectId: id),
              );
            },
          ),
          GoRoute(
            path: 'history/:sessionId',
            name: 'historyDetail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              final sessionId = state.pathParameters['sessionId']!;
              return _fadeRisePage(
                key: state.pageKey,
                child: HistoryDetailScreen(
                  subjectId: id,
                  sessionId: sessionId,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _fadeRisePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'request-code',
            name: 'requestActivationCode',
            pageBuilder: (context, state) => _fadeRisePage(
              key: state.pageKey,
              child: const RequestActivationCodeScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        pageBuilder: (context, state) {
          final subjectId = state.uri.queryParameters['subjectId'] ??
              ref.read(overlaySubjectIdProvider);
          return _fadeRisePage(
            key: state.pageKey,
            child: HistoryScreen(subjectId: subjectId),
          );
        },
      ),
      if (_isDesktop)
        GoRoute(
          path: '/overlay',
          name: 'overlay',
          pageBuilder: (context, state) => _fadeRisePage(
            key: state.pageKey,
            child: const OverlayScreen(),
          ),
        ),
    ],
  );
});
