import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/hymnal/presentation/hymn_page.dart';
import '../../features/hymnal/presentation/section_list_screen.dart';
import '../../features/readings/presentation/reading_page.dart';
import '../../features/readings/presentation/readings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/home_shell.dart';

String sectionPath(String id) => '/section/$id';
String hymnPath(String id) => '/hymn/$id';
String readingPath(String id) => '/reading/$id';

/// Where the app starts; tests override it to open a page directly.
final initialLocationProvider = Provider<String>((ref) => '/');

/// Tabs (Hymns, Readings, Settings) keep their own history; hymn and reading pages
/// cover the tab bar (spec section 3).
final routerProvider = Provider<GoRouter>((ref) {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: ref.watch(initialLocationProvider),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'section/:id',
                    builder: (_, state) => SectionListScreen(
                      sectionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/readings',
                builder: (_, _) => const ReadingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/hymn/:id',
        parentNavigatorKey: root,
        builder: (_, state) => HymnPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reading/:id',
        parentNavigatorKey: root,
        builder: (_, state) => ReadingPage(id: state.pathParameters['id']!),
      ),
    ],
  );
});
