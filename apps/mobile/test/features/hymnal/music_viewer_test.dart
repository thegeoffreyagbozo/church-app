import 'package:church_app/features/hymnal/presentation/music_pages.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  const music = ReadingSettings(
    theme: ReadingTheme.paper,
    hymnView: HymnViewMode.chorister,
  );

  testWidgets('tapping the music opens it full screen; Close goes back', (
    tester,
  ) async {
    final platform = await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: music,
    );

    await tester.ensureVisible(find.byType(MusicPages));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MusicPages));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(platform.screen.awake, isTrue);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('How Firm a Foundation'), findsWidgets);
  });

  testWidgets('a double tap zooms in, and another zooms back out', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/hymn/hymn-41/music', settings: music);
    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    final point = tester.getCenter(find.byType(MusicPages));

    Future<void> doubleTap() async {
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
    }

    await doubleTap();
    expect(scale(), closeTo(2.5, 0.01));
    await doubleTap();
    expect(scale(), closeTo(1, 0.01));
  });
}
