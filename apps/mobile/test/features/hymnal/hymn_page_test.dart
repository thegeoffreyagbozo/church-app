import 'package:church_app/features/hymnal/presentation/hymn_page.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:church_app/features/settings/presentation/settings_controller.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  ReadingSettings settingsOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(HymnPage)),
  ).read(readingSettingsProvider);

  testWidgets('shows the kicker, number, title and credits', (tester) async {
    await pumpApp(tester, db, location: '/hymn/hymn-41');

    expect(find.text('HYMN'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('How Firm a Foundation'), findsOneWidget);
    expect(
      find.text(
        '"K" in Rippon\'s Selection, 1787 · '
        'From Caldwell\'s Union Harmony, 1837',
      ),
      findsOneWidget,
    );
  });

  testWidgets('names other sections and joins a translation credit', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/hymn/supp-2');

    expect(find.text('SUPPLEMENTARY'), findsOneWidget);
    expect(
      find.text(
        'Edmond L. Budry, 1854-1932, translated by Richard B. Hoyle, '
        '1875-1939 · George Frederick Handel, 1685-1759',
      ),
      findsOneWidget,
    );
  });

  testWidgets('repeats the chorus in full after every verse', (tester) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/hymn/supp-1');

    expect(find.text('CHORUS'), findsNWidgets(2));
    expect(
      find.text(
        'This is my story, this is my song,\n'
        'Praising my Saviour all the day long.',
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('Music shows only what the book prints', (tester) async {
    await pumpApp(tester, db, location: '/hymn/supp-1');

    await tester.tap(find.byTooltip('Music'));
    await tester.pumpAndSettle();

    expect(find.text('MUSIC'), findsOneWidget);
    expect(find.text('Assurance'), findsOneWidget);
    expect(find.text('Phoebe P. Knapp, 1839-1908'), findsOneWidget);
    expect(find.text('Key'), findsOneWidget);
    expect(settingsOf(tester).hymnView, HymnViewMode.chorister);
  });

  testWidgets('also-sung-to tunes open the hymn when the app has it', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: const ReadingSettings(
        theme: ReadingTheme.paper,
        hymnView: HymnViewMode.chorister,
      ),
    );

    expect(
      find.text('Adeste Fideles · 100 (not in the app yet)'),
      findsOneWidget,
    );
    await tester.tap(find.text('Toplady · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Rock of Ages'), findsWidgets);
  });

  testWidgets('pins the number and title once they scroll away', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: const ReadingSettingsForTest(textScale: 2).settings,
    );
    final compactTitle = find.byKey(const ValueKey('compact-title'));
    expect(compactTitle, findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(compactTitle, findsOneWidget);
    expect(
      find.descendant(of: compactTitle, matching: find.text('41')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the number and title pinned far down a long hymn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: const ReadingSettingsForTest(textScale: 2).settings,
    );

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('compact-title')), findsOneWidget);
  });

  testWidgets('keeps the screen on while open, then lets it sleep', (
    tester,
  ) async {
    final platform = await pumpApp(
      tester,
      db,
      location: '/section/section-hymns',
    );
    await tester.tap(find.text('How Firm a Foundation'));
    await tester.pumpAndSettle();
    expect(platform.screen.awake, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(platform.screen.awake, isFalse);
  });

  testWidgets(
    'lets the screen sleep in the background, and wakes it on return',
    (tester) async {
      final platform = await pumpApp(tester, db, location: '/hymn/hymn-41');
      expect(platform.screen.awake, isTrue);

      // Apps pass through inactive on the way to and from the background.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(platform.screen.awake, isFalse);

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(platform.screen.awake, isTrue);
    },
  );

  testWidgets('keeps the screen on after returning from another hymn', (
    tester,
  ) async {
    final platform = await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: const ReadingSettings(hymnView: HymnViewMode.chorister),
    );

    // "Also sung to" opens hymn 1 on top of hymn 41.
    await tester.tap(find.text('Toplady · 1'));
    await tester.pumpAndSettle();
    expect(platform.screen.awake, isTrue);
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();

    expect(find.text('How Firm a Foundation'), findsWidgets);
    expect(platform.screen.awake, isTrue);
  });

  testWidgets('keeps lines readable on a tablet', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, db, location: '/hymn/hymn-41');

    final verse = find.textContaining('How firm a foundation, ye saints');
    expect(tester.getSize(verse.last).width, lessThanOrEqualTo(680));
  });

  testWidgets('leaves the screen alone when the setting is off', (
    tester,
  ) async {
    final platform = await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: const ReadingSettingsForTest(keepScreenOn: false).settings,
    );

    expect(platform.screen.awake, isFalse);
  });

  testWidgets('pinching changes the text size and saves it', (tester) async {
    await pumpApp(tester, db, location: '/hymn/hymn-41');
    final center = tester.getCenter(find.byType(CustomScrollView));

    final first = await tester.startGesture(center - const Offset(0, 40));
    final second = await tester.startGesture(
      center + const Offset(0, 40),
      pointer: 2,
    );
    await first.moveBy(const Offset(0, -20));
    await second.moveBy(const Offset(0, 20));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(settingsOf(tester).textScale, closeTo(1.5, 0.01));
    expect((await UserData(db).settings())['text_scale'], '1.50');
  });

  testWidgets('says so when the hymn is no longer in the book', (tester) async {
    await pumpApp(tester, db, location: '/hymn/gone');

    expect(find.text('This is no longer in the hymn book.'), findsOneWidget);
  });

  testWidgets('an opened hymn appears under recently opened', (tester) async {
    await pumpApp(tester, db);

    await tester.tap(find.text('Supplementary Hymns'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blessed Assurance'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('SUPPLEMENTARY'), findsOneWidget);
    expect(find.text('Blessed Assurance'), findsOneWidget);
  });
}
