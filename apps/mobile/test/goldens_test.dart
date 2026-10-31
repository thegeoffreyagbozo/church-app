import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import 'helpers/test_app.dart';

/// Screenshots of the main screens at 1x and 2x text, in the bundled fonts (spec
/// section 9). Regenerate with:
///   flutter test --update-goldens test/goldens_test.dart
void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  /// A 393 x 852 phone; [textScale] is the phone's own text size.
  void phone(WidgetTester tester, {double textScale = 1}) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> snap(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final theme in [ReadingTheme.paper, ReadingTheme.night]) {
    for (final view in HymnViewMode.values) {
      for (final size in [1.0, 2.0]) {
        final label = view == HymnViewMode.ordinary ? 'words' : 'music';
        final name = 'hymn_${theme.name}_${label}_${size.toInt()}x';
        testWidgets(name, (tester) async {
          phone(tester);
          await pumpApp(
            tester,
            db,
            location: '/hymn/supp-1',
            settings: ReadingSettings(
              theme: theme,
              hymnView: view,
              textScale: size,
            ),
          );
          await snap(name);
        });
      }
    }
  }

  for (final theme in [ReadingTheme.paper, ReadingTheme.night]) {
    final name = 'hymn_${theme.name}_score_1x';
    testWidgets(name, (tester) async {
      phone(tester);
      await pumpApp(
        tester,
        db,
        location: '/hymn/hymn-41',
        settings: ReadingSettings(
          theme: theme,
          hymnView: HymnViewMode.chorister,
        ),
      );
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      await snap(name);
    });
  }

  for (final theme in [ReadingTheme.paper, ReadingTheme.night]) {
    final name = 'hymn_${theme.name}_notation_1x';
    testWidgets(name, (tester) async {
      phone(tester);
      await pumpApp(
        tester,
        db,
        location: '/hymn/hymn-1',
        settings: ReadingSettings(
          theme: theme,
          hymnView: HymnViewMode.chorister,
        ),
      );
      await snap(name);
    });
  }

  for (final (theme, size) in [
    (ReadingTheme.paper, 1.0),
    (ReadingTheme.paper, 2.0),
    (ReadingTheme.night, 1.0),
  ]) {
    final name = 'reading_${theme.name}_${size.toInt()}x';
    testWidgets(name, (tester) async {
      phone(tester);
      await pumpApp(
        tester,
        db,
        location: '/reading/reading-1',
        settings: ReadingSettings(theme: theme, textScale: size),
      );
      await snap(name);
    });
  }

  for (final size in [1.0, 2.0]) {
    final name = 'home_paper_${size.toInt()}x';
    testWidgets(name, (tester) async {
      phone(tester, textScale: size);
      var minute = 0;
      final user = UserData(
        db,
        clock: () => DateTime.utc(2026, 1, 1, 9, minute++),
      );
      await user.markOpened(ItemType.reading, 'reading-3');
      await user.markOpened(ItemType.hymn, 'supp-2');
      await user.markOpened(ItemType.hymn, 'hymn-41');
      await pumpApp(tester, db);
      await snap(name);
    });
  }

  for (final size in [1.0, 2.0]) {
    final name = 'home_empty_paper_${size.toInt()}x';
    testWidgets(name, (tester) async {
      phone(tester, textScale: size);
      await pumpApp(tester, db);
      await snap(name);
    });
  }
}
