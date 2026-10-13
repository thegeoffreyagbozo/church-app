import 'dart:io';

import 'package:church_app/app.dart';
import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/core/platform/platform_services.dart';
import 'package:church_app/core/router/app_router.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:church_app/features/settings/presentation/settings_controller.dart';
import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory hymn book holding content_db's public-domain sample.
Future<ContentDatabase> sampleDatabase() async {
  final db = ContentDatabase(NativeDatabase.memory());
  final json = File(
    '../../packages/content_db/test/fixtures/sample_content.json',
  ).readAsStringSync();
  await importSnapshot(db, ContentSnapshot.parse(json));
  await rebuildSearchIndex(db);
  return db;
}

class FakeScreenAwake extends ScreenAwake {
  bool awake = false;

  @override
  Future<void> enable() async => awake = true;

  @override
  Future<void> disable() async => awake = false;
}

class FakeSharing extends Sharing {
  final shared = <String>[];

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      shared.add(text);
}

/// Opens nothing; records what the app asked for.
class FakeLauncher extends Launcher {
  FakeLauncher({this.installed = const {}});

  /// URI schemes that can be opened, such as "whatsapp".
  final Set<String> installed;
  final opened = <Uri>[];

  @override
  Future<bool> canOpen(Uri uri) async => installed.contains(uri.scheme);

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Fakes for the plugins, shared by every widget test.
class TestPlatform {
  final screen = FakeScreenAwake();
  final sharing = FakeSharing();
  FakeLauncher launcher = FakeLauncher();
}

/// Pumps the app on [db] at [location], with fake plugins.
Future<TestPlatform> pumpApp(
  WidgetTester tester,
  ContentDatabase db, {
  String location = '/',
  ReadingSettings settings = const ReadingSettings(theme: ReadingTheme.paper),
  TestPlatform? platform,
  List<Override> overrides = const [],
}) async {
  final fakes = platform ?? TestPlatform();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        contentDatabaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
        initialLocationProvider.overrideWithValue(location),
        solidSurfacesProvider.overrideWith((ref) => false),
        appVersionProvider.overrideWith((ref) => '1.0.0 (1)'),
        screenAwakeProvider.overrideWithValue(fakes.screen),
        sharingProvider.overrideWithValue(fakes.sharing),
        launcherProvider.overrideWithValue(fakes.launcher),
        ...overrides,
      ],
      child: const HymnalApp(),
    ),
  );
  await tester.pumpAndSettle();
  return fakes;
}

/// Paper settings with a few changes, for tests.
class ReadingSettingsForTest {
  const ReadingSettingsForTest({
    this.digitRow = true,
    this.keepScreenOn = true,
    this.textScale = 1.0,
  });

  final bool digitRow;
  final bool keepScreenOn;
  final double textScale;

  ReadingSettings get settings => ReadingSettings(
    theme: ReadingTheme.paper,
    digitRow: digitRow,
    keepScreenOn: keepScreenOn,
    textScale: textScale,
  );
}

/// A screen tall enough to show a whole hymn without scrolling.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
