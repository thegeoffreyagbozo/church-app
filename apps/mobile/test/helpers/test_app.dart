import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:church_app/app.dart';
import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/core/platform/platform_services.dart';
import 'package:church_app/core/router/app_router.dart';
import 'package:church_app/features/hymnal/data/hymnal_providers.dart';
import 'package:church_app/features/hymnal/data/notation_drawer.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:church_app/features/settings/presentation/settings_controller.dart';
import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:notation/notation.dart';
import 'package:notation/testing.dart';

/// content_db's public-domain sample, as the Supabase API returns it.
String sampleContentJson() => File(
  '../../packages/content_db/test/fixtures/sample_content.json',
).readAsStringSync();

/// An in-memory hymn book holding content_db's public-domain sample. The hymns in
/// [notationOn] get drawn notation (the Old Hundredth fixture) with [verses] verses.
Future<ContentDatabase> sampleDatabase({
  Set<String> notationOn = const {'hymn-1'},
  int verses = 4,
}) async {
  final db = ContentDatabase(NativeDatabase.memory());
  final json = jsonDecode(sampleContentJson()) as Map<String, Object?>;
  final assets = json['hymn_assets']! as List<Object?>;
  for (final id in notationOn) {
    assets.add({
      'id': 'notation-$id',
      'hymn_id': id,
      'kind': 'musicxml',
      'storage_bucket': 'sheet-music',
      'storage_path': '$id/notation.mxl',
      'sort_order': 0,
    });
  }
  await importSnapshot(
    db,
    ContentSnapshot.parse(jsonEncode(json)),
    musicSizes: const {
      'music-41-1': ImageSize(1200, 900),
      'music-41-2': ImageSize(1200, 500),
      'music-doxology-1': ImageSize(1200, 700),
    },
    notation: {
      for (final id in notationOn)
        id: BundledNotation(
          Uint8List.fromList(utf8.encode(oldHundredth())),
          verses,
        ),
    },
  );
  await rebuildSearchIndex(db);
  return db;
}

/// A small black-on-white PNG standing in for a piece of printed music.
final Uint8List testMusicPng = () {
  final image = img.Image(width: 120, height: 90)
    ..clear(img.ColorRgb8(255, 255, 255));
  for (var y = 20; y < 70; y += 10) {
    img.drawLine(
      image,
      x1: 5,
      y1: y,
      x2: 115,
      y2: y,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
  return img.encodePng(image);
}();

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

/// Draws nothing: returns a fixed SVG (two staff lines) or fails, and records requests.
class FakeNotationDrawer implements NotationDrawer {
  FakeNotationDrawer({this.fail = false});

  bool fail;
  final requests = <({int verse, HymnPart part, int scale, double width})>[];

  /// When set, drawings wait for it, so a test can see the in-between state.
  Completer<void>? hold;

  static const svg =
      '<svg width="300px" height="80px" xmlns="http://www.w3.org/2000/svg">'
      '<rect x="0" y="20" width="300" height="2"/>'
      '<rect x="0" y="60" width="300" height="2"/></svg>';

  @override
  void warmUp() {}

  @override
  Future<List<String>> draw(
    String musicXml, {
    required double width,
    required int verse,
    required HymnPart part,
    required int scale,
  }) async {
    requests.add((verse: verse, part: part, scale: scale, width: width));
    await hold?.future;
    if (fail) throw const NotationException('fake failure');
    return [svg];
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
  ImageProvider Function(String id)? musicImage,
  NotationDrawer? notation,
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
        musicImageProvider.overrideWithValue(
          musicImage ?? (_) => MemoryImage(testMusicPng),
        ),
        notationDrawerProvider.overrideWithValue(
          notation ?? FakeNotationDrawer(),
        ),
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
