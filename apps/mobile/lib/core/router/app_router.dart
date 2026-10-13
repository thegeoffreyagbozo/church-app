import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/hymnal/presentation/hymn_page.dart';
import '../../features/hymnal/presentation/section_list_screen.dart';

String sectionPath(String id) => '/section/$id';
String hymnPath(String id) => '/hymn/$id';
String readingPath(String id) => '/reading/$id';

/// Where the app starts; tests override it to open a page directly.
final initialLocationProvider = Provider<String>((ref) => '/');

/// Home, its section lists and hymn pages. Readings and the tab bar join in later tasks.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: HomeScreen()),
        routes: [
          GoRoute(
            path: 'section/:id',
            builder: (_, state) =>
                SectionListScreen(sectionId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/hymn/:id',
        builder: (_, state) => HymnPage(id: state.pathParameters['id']!),
      ),
    ],
  );
});
