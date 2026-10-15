import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  /// The span a reading line was drawn with (Text.rich wraps it in its own span).
  TextSpan lineSpan(WidgetTester tester, String text) {
    final rich = tester.widget<RichText>(
      find.textContaining(text, findRichText: true).first,
    );
    return (rich.text as TextSpan).children!.single as TextSpan;
  }

  BoxDecoration? bandBehind(WidgetTester tester, String text) {
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.textContaining(text, findRichText: true).first,
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration as BoxDecoration?;
  }

  testWidgets('shows two voices, the bold one on a band, with no labels', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/reading/reading-1');

    expect(find.text('RESPONSIVE READING'), findsOneWidget);
    expect(find.text('Psalm 23'), findsOneWidget);
    expect(find.textContaining('LEADER'), findsNothing);
    expect(find.textContaining('PEOPLE'), findsNothing);
    expect(lineSpan(tester, 'He maketh me').style!.fontWeight, FontWeight.w700);
    expect(bandBehind(tester, 'He maketh me'), isNotNull);
    expect(
      lineSpan(tester, 'The Lord is my shepherd').style!.fontWeight,
      isNot(FontWeight.w700),
    );
    expect(bandBehind(tester, 'The Lord is my shepherd'), isNull);
  });

  testWidgets('a creed is read together, in plain text', (tester) async {
    await pumpApp(tester, db, location: '/reading/reading-creed');

    expect(find.text('CREED'), findsOneWidget);
    expect(find.text('Everyone reads together'), findsOneWidget);
    expect(bandBehind(tester, 'I believe in God'), isNull);
  });

  testWidgets('a collection shows each item with its number and reference', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/reading/reading-3');

    expect(find.text('READING'), findsOneWidget);
    expect(find.text('Numbers 6:24-26'), findsOneWidget);
    expect(find.text('II Corinthians 13:14'), findsOneWidget);
  });

  testWidgets('shows bullets and bold words in a covenant', (tester) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/reading/reading-covenant');

    expect(find.text('•'), findsNWidgets(2));
    final runs = lineSpan(
      tester,
      'together in Christian love',
    ).children!.cast<TextSpan>();
    final walk = runs.firstWhere((s) => s.text == 'walk');
    expect(walk.style!.fontWeight, FontWeight.w700);
  });
}
