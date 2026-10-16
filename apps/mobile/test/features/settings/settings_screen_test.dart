import 'package:church_app/features/settings/presentation/settings_screen.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets('turning a setting off saves it', (tester) async {
    await pumpApp(tester, db, location: '/settings');
    // Scroll the row up from behind the tab bar, as a person would.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Number row above the keyboard'));
    await tester.pumpAndSettle();

    expect((await UserData(db).settings())['digit_row'], 'false');
  });

  testWidgets('Night switches the app to the night palette', (tester) async {
    await pumpApp(tester, db, location: '/settings');

    await tester.tap(find.text('Night'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect((await UserData(db).settings())['theme'], 'night');
  });

  testWidgets('extra-legible type swaps the typeface', (tester) async {
    await pumpApp(tester, db, location: '/settings');

    await tester.tap(find.text('Extra-legible type'));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.text('Settings'),
      ),
    );
    expect(title.style!.fontFamily, 'AtkinsonHyperlegible');
  });

  testWidgets('About shows the version and licences, not a website', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/settings');

    expect(find.text('https://example.church'), findsNothing);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    await tester.tap(find.text('Licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('the text size slider goes down to half size in 10% steps', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/settings');

    final slider = tester.widget<Slider>(find.byType(Slider));

    expect(slider.min, 0.5);
    expect((slider.max - slider.min) / slider.divisions!, closeTo(0.1, 1e-9));
  });

  testWidgets(
    'says the text size changes only the words of hymns and readings',
    (tester) async {
      await pumpApp(tester, db, location: '/settings');

      final hint = find.text(
        'Changes the words of hymns and readings. The rest of the app follows '
        "your phone's text size.",
      );
      expect(hint, findsOneWidget);
      expect(
        tester.getTopLeft(hint).dy,
        greaterThan(tester.getTopLeft(find.text('Text size')).dy),
      );
      expect(
        tester.getTopLeft(hint).dy,
        lessThan(tester.getTopLeft(find.byType(Slider)).dy),
      );
    },
  );
}
