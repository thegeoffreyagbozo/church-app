import 'dart:async';

import 'package:church_app/core/config/church_config.dart';
import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/core/widgets/item_row.dart';
import 'package:church_app/features/home/presentation/home_screen.dart';
import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/text_lines.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  /// [text] on Home itself (the tab bar, added later, also says "Hymns").
  Finder onHome(String text) =>
      find.descendant(of: find.byType(HomeScreen), matching: find.text(text));

  testWidgets('shows the church, the sections and an empty recent list', (
    tester,
  ) async {
    await pumpApp(tester, db);

    expect(find.text('Grace Chapel'), findsOneWidget);
    expect(find.text('Service Music'), findsOneWidget);
    expect(find.text('Supplementary Hymns'), findsOneWidget);
    expect(find.text('Nothing opened yet'), findsOneWidget);
    expect(
      find.text('Hymns and readings you open will appear here, newest first.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no empty note while the recent list is still loading', (
    tester,
  ) async {
    final recent = Completer<List<RecentItem>>();
    await pumpApp(
      tester,
      db,
      overrides: [recentProvider.overrideWith((ref) => recent.future)],
    );
    expect(find.text('Nothing opened yet'), findsNothing);

    recent.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('Nothing opened yet'), findsOneWidget);
  });

  testWidgets('Find a hymn on the empty recent list opens the search', (
    tester,
  ) async {
    // A phone's height, so the button sits on screen below the section rows.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, db);
    final search = find.byType(EditableText);
    expect(tester.widget<EditableText>(search).focusNode.hasFocus, isFalse);

    await tester.tap(find.text('Find a hymn'));
    await tester.pump();

    expect(tester.widget<EditableText>(search).focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('shows the church logo left of its name', (tester) async {
    final logo = MemoryImage(img.encodePng(img.Image(width: 4, height: 4)));
    await pumpApp(
      tester,
      db,
      overrides: [churchLogoProvider.overrideWithValue(logo)],
    );

    final image = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Image),
    );
    expect(tester.widget<Image>(image).image, logo);
    final logoRect = tester.getRect(image);
    final nameRect = tester.getRect(find.text('Grace Chapel'));
    expect(logoRect.right, lessThan(nameRect.left));
    expect(logoRect.top, lessThan(nameRect.center.dy));
    expect(logoRect.bottom, greaterThan(nameRect.center.dy));
  });

  testWidgets("starts the church's tagline under the logo, not the name", (
    tester,
  ) async {
    final logo = MemoryImage(img.encodePng(img.Image(width: 4, height: 4)));
    await db
        .update(db.church)
        .write(const ChurchCompanion(tagline: Value('Where all are welcome')));
    await pumpApp(
      tester,
      db,
      overrides: [churchLogoProvider.overrideWithValue(logo)],
    );

    final logoRect = tester.getRect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(Image),
      ),
    );
    final taglineRect = tester.getRect(find.text('Where all are welcome'));
    expect(taglineRect.left, logoRect.left);
    expect(taglineRect.top, greaterThanOrEqualTo(logoRect.bottom));
  });

  testWidgets('wraps a long tagline to the width of the phone', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const tagline =
        'Where all are welcome and every voice joins the song of praise';
    await db
        .update(db.church)
        .write(const ChurchCompanion(tagline: Value(tagline)));
    await pumpApp(tester, db);

    expect(linesOf(tester, tagline), 2);
  });

  testWidgets('shows the name alone when the church has no logo', (
    tester,
  ) async {
    await pumpApp(tester, db);

    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('shows the sections as rows that open a page', (tester) async {
    await pumpApp(tester, db);

    expect(onHome('BROWSE'), findsOneWidget);
    final row = find.ancestor(
      of: onHome('Service Music'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
        of: row.first,
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
      findsOneWidget,
    );
    // The rows run down the page rather than wrapping like chips.
    final hymns = tester.getTopLeft(onHome('Hymns'));
    final supplementary = tester.getTopLeft(onHome('Supplementary Hymns'));
    expect(supplementary.dx, hymns.dx);
    expect(supplementary.dy, greaterThan(hymns.dy));
  });

  testWidgets(
    'lists the main hymns first, then other numbered sections, then the rest',
    (tester) async {
      await pumpApp(tester, db);

      /// Whether row [a] comes before row [b] in reading order.
      bool before(Offset a, Offset b) =>
          a.dy < b.dy || (a.dy == b.dy && a.dx < b.dx);
      final hymns = tester.getTopLeft(onHome('Hymns'));
      final supplementary = tester.getTopLeft(onHome('Supplementary Hymns'));
      final service = tester.getTopLeft(onHome('Service Music'));
      expect(before(hymns, supplementary), isTrue);
      expect(before(supplementary, service), isTrue);
    },
  );

  testWidgets('a numbered section lists its hymns by number', (tester) async {
    useTallScreen(tester);
    await pumpApp(tester, db);

    await tester.tap(onHome('Hymns'));
    await tester.pumpAndSettle();

    // Within the rows: a part's range label can also read "7".
    final numbers = ['1', '2', '7', '41'].map(
      (n) => tester
          .getTopLeft(
            find.descendant(of: find.byType(ItemRow), matching: find.text(n)),
          )
          .dy,
    );
    expect(numbers.toList(), orderedEquals([...numbers]..sort()));
    expect(find.text('Rock of Ages, cleft for me'), findsOneWidget);
  });

  testWidgets('an unnumbered section lists its hymns with their topic', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/section/section-service');

    expect(find.text('Service Music'), findsOneWidget);
    expect(find.text('Doxology'), findsOneWidget);
    expect(find.text('COMMUNION'), findsOneWidget);
  });
}
