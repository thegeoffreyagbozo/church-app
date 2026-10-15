import 'package:church_app/features/hymnal/presentation/hymn_page.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets('a number shows as the top result and Go opens it', (
    tester,
  ) async {
    await pumpApp(tester, db);

    await tester.enterText(find.byType(TextField), '41');
    await tester.pumpAndSettle();
    expect(find.text('Press Go to open'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(find.byType(HymnPage), findsOneWidget);
    expect(find.text('How Firm a Foundation'), findsWidgets);
  });

  testWidgets(
    'Go right after typing opens what was typed, not an earlier result',
    (tester) async {
      await pumpApp(tester, db);
      // "s" alone finds other hymns; "s2" is Supplementary 2.
      await tester.enterText(find.byType(TextField), 's');
      await tester.pumpAndSettle();

      // Type the 2 and press Go at once, before the search for "s2" finishes
      // (tester.enterText would wait for it).
      tester.testTextInput.enterText('s2');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      expect(find.byType(HymnPage), findsOneWidget);
      expect(find.text('Thine Is the Glory'), findsOneWidget);
    },
  );

  testWidgets('the number row types into the search', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('digit-4')));
    await tester.tap(find.byKey(const ValueKey('digit-1')));
    await tester.pumpAndSettle();

    expect(find.text('41'), findsWidgets);
    expect(find.text('Press Go to open'), findsOneWidget);
  });

  testWidgets('the number row hides with the keyboard', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('digit-1')), findsOneWidget);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('digit-1')), findsNothing);
  });

  testWidgets('the number row can be turned off', (tester) async {
    await pumpApp(
      tester,
      db,
      settings: const ReadingSettingsForTest(digitRow: false).settings,
    );
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('digit-1')), findsNothing);
  });

  String searchText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets(
    'a tap outside the search hides the keyboard, keeping the words',
    (tester) async {
      await pumpApp(tester, db);
      await tester.enterText(find.byType(TextField), 'grace');
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.text('Grace Chapel'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(searchText(tester), 'grace');
    },
  );

  testWidgets('the number row and the clear button keep the keyboard up', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('digit-4')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(searchText(tester), isEmpty);
  });

  testWidgets('words find hymns with the matched words highlighted', (
    tester,
  ) async {
    await pumpApp(tester, db);

    await tester.enterText(find.byType(TextField), 'How firm');
    await tester.pumpAndSettle();

    expect(find.text('1 RESULT'), findsOneWidget);
    expect(
      find.text('How Firm a Foundation', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('names the verse a match is in', (tester) async {
    await pumpApp(tester, db);

    await tester.enterText(find.byType(TextField), 'labours');
    await tester.pumpAndSettle();

    expect(find.textContaining('VERSE 2', findRichText: true), findsOneWidget);
  });

  testWidgets('says when a number is not in the book', (tester) async {
    await pumpApp(tester, db);

    await tester.enterText(find.byType(TextField), '999');
    await tester.pumpAndSettle();

    expect(
      find.text('No hymn 999 in Hymns. This book has 1 to 41.'),
      findsOneWidget,
    );
  });

  testWidgets('says calmly when nothing matches', (tester) async {
    await pumpApp(tester, db);

    await tester.enterText(find.byType(TextField), 'xylophone');
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing matches'), findsOneWidget);
  });
}
