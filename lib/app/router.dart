import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/features/history/presentation/history_list.dart';
import 'package:studee_pc/features/ingestion/presentation/ingestion_screen.dart';
import 'package:studee_pc/features/overlay/presentation/overlay_panel.dart';
import 'package:studee_pc/features/settings/presentation/settings_screen.dart';
import 'package:studee_pc/features/solver/presentation/solve_screen.dart';
import 'package:studee_pc/features/subjects/presentation/subject_detail_screen.dart';
import 'package:studee_pc/features/subjects/presentation/subjects_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'subjects',
        builder: (context, state) => const SubjectsListScreen(),
      ),
      GoRoute(
        path: '/subjects/:id',
        name: 'subjectDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubjectDetailScreen(subjectId: id);
        },
        routes: [
          GoRoute(
            path: 'import',
            name: 'import',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return IngestionScreen(subjectId: id);
            },
          ),
          GoRoute(
            path: 'solve',
            name: 'solve',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SolveScreen(subjectId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) {
          final subjectId = state.uri.queryParameters['subjectId'] ??
              ref.read(overlaySubjectIdProvider);
          return HistoryScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/overlay',
        name: 'overlay',
        builder: (context, state) => const OverlayScreen(),
      ),
    ],
  );
});
