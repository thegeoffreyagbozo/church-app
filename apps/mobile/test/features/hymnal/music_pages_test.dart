import 'dart:typed_data';

import 'package:church_app/features/hymnal/presentation/music_pages.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../helpers/test_app.dart';

/// [m] applied to one RGBA pixel (0 to 255 per channel), as a colour filter does.
List<double> apply(List<double> m, List<double> rgba) => [
  for (var row = 0; row < 4; row++)
    m[row * 5] * rgba[0] +
        m[row * 5 + 1] * rgba[1] +
        m[row * 5 + 2] * rgba[2] +
        m[row * 5 + 3] * rgba[3] +
        m[row * 5 + 4],
];

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  const music = ReadingSettings(
    theme: ReadingTheme.paper,
    hymnView: HymnViewMode.chorister,
  );

  test('ink is drawn in the theme colour and paper becomes clear', () {
    final m = inkMatrix(const Color(0xFF203040));
    final black = apply(m, [0, 0, 0, 255]);
    final white = apply(m, [255, 255, 255, 255]);
    expect(black.map((v) => v.round()), [0x20, 0x30, 0x40, 255]);
    expect(white[3], closeTo(0, 0.5));
  });

  test('a clear pixel stays clear, so the ink never covers the page', () {
    final m = inkMatrix(const Color(0xFF203040));
    expect(apply(m, [0, 0, 0, 0])[3], closeTo(0, 0.5));
  });

  testWidgets('lays out every piece at its own shape, the width of the page', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/hymn/hymn-41', settings: music);

    final pieces = tester.widgetList<AspectRatio>(
      find.descendant(
        of: find.byType(MusicPages),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(pieces.map((a) => a.aspectRatio), [1200 / 900, 1200 / 500]);
  });

  for (final size in [const Size(320, 640), const Size(852, 393)]) {
    testWidgets(
      'fits a ${size.width.toInt()} x ${size.height.toInt()} screen',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpApp(tester, db, location: '/hymn/hymn-41', settings: music);

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(MusicPages)).width,
          lessThanOrEqualTo(size.width),
        );
      },
    );
  }

  testWidgets('a music file the app lacks shows a line, not a broken image', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: music,
      musicImage: (_) => MemoryImage(Uint8List.fromList([1, 2, 3])),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('This music could not be shown.'), findsWidgets);
  });
}
