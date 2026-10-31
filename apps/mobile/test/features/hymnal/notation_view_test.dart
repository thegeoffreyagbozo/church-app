import 'dart:async';

import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../helpers/test_app.dart';

const _music = ReadingSettings(
  theme: ReadingTheme.paper,
  hymnView: HymnViewMode.chorister,
);

void main() {
  late ContentDatabase db;
  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets(
    'a hymn with notation shows the drawing, a chip per verse and the parts',
    (tester) async {
      useTallScreen(tester);
      final drawer = FakeNotationDrawer();
      await pumpApp(
        tester,
        db,
        location: '/hymn/hymn-1',
        settings: _music,
        notation: drawer,
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '4'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(drawer.requests.first.verse, 1);
    },
  );

  testWidgets(
    'drawing starts for every verse as soon as the hymn opens, in Words too',
    (tester) async {
      final drawer = FakeNotationDrawer();
      await pumpApp(tester, db, location: '/hymn/hymn-1', notation: drawer);

      expect(drawer.requests.map((r) => r.verse).toSet(), {1, 2, 3, 4});
      expect(find.byType(SvgPicture), findsNothing);
    },
  );

  testWidgets('a verse chip draws that verse', (tester) async {
    useTallScreen(tester);
    final drawer = FakeNotationDrawer();
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-1',
      settings: _music,
      notation: drawer,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pumpAndSettle();

    expect(drawer.requests.last.verse, 3);
  });

  testWidgets('the part is remembered for the next hymn', (tester) async {
    useTallScreen(tester);
    await db.close();
    db = await sampleDatabase(notationOn: {'hymn-1', 'hymn-41'});
    final drawer = FakeNotationDrawer();
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-1',
      settings: _music,
      notation: drawer,
    );

    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();
    expect(drawer.requests.last.part, HymnPart.tenor);

    GoRouter.of(tester.element(find.byType(SvgPicture))).go('/hymn/hymn-41');
    await tester.pumpAndSettle();
    expect(drawer.requests.last.part, HymnPart.tenor);
  });

  testWidgets('one verse means no verse chips', (tester) async {
    useTallScreen(tester);
    await db.close();
    db = await sampleDatabase(verses: 1);
    await pumpApp(tester, db, location: '/hymn/hymn-1', settings: _music);

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('while a new drawing is made, the last one stays on screen', (
    tester,
  ) async {
    useTallScreen(tester);
    final drawer = FakeNotationDrawer();
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-1',
      settings: _music,
      notation: drawer,
    );

    drawer.hold = Completer<void>();
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);

    drawer.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('if drawing fails, the scanned music shows instead', (
    tester,
  ) async {
    useTallScreen(tester);
    await db.close();
    db = await sampleDatabase(notationOn: {'hymn-41'});
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: _music,
      notation: FakeNotationDrawer(fail: true),
    );

    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(Image), findsWidgets); // hymn 41's scanned pieces
  });

  testWidgets('a hymn without notation keeps its scanned music', (
    tester,
  ) async {
    useTallScreen(tester);
    final drawer = FakeNotationDrawer();
    await pumpApp(
      tester,
      db,
      location: '/hymn/hymn-41',
      settings: _music,
      notation: drawer,
    );

    expect(find.byType(SvgPicture), findsNothing);
    expect(drawer.requests, isEmpty);
  });

  testWidgets("a hymn with notation doesn't say it has no music", (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/hymn/hymn-1', settings: _music);

    expect(
      find.text('The choir book has no printed music for this hymn.'),
      findsNothing,
    );
  });

  testWidgets(
    'a drawing that fails after an earlier one worked never leaves the old one up',
    (tester) async {
      useTallScreen(tester);
      await db.close();
      db = await sampleDatabase(notationOn: {'hymn-41'});
      final drawer = FakeNotationDrawer();
      await pumpApp(
        tester,
        db,
        location: '/hymn/hymn-41',
        settings: _music,
        notation: drawer,
      );
      expect(find.byType(SvgPicture), findsOneWidget);

      drawer.fail = true;
      await tester.tap(find.widgetWithText(ChoiceChip, '3'));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(Image), findsWidgets); // the scanned music instead
    },
  );

  testWidgets(
    'drawing ahead goes one verse at a time, so the screen never waits '
    'behind a queue',
    (tester) async {
      final drawer = FakeNotationDrawer()..hold = Completer<void>();
      await pumpApp(tester, db, location: '/hymn/hymn-1', notation: drawer);

      expect(drawer.requests, hasLength(1));

      drawer.hold!.complete();
      await tester.pumpAndSettle();
      expect(drawer.requests.map((r) => r.verse).toList(), [1, 2, 3, 4]);
    },
  );
}
