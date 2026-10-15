import 'package:church_app/features/readings/presentation/reading_page.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets('puts the covenant and creed first, then numbered readings', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/readings');

    expect(find.text('COVENANT'), findsOneWidget);
    expect(find.text('CREED'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('The Church Covenant')).dy,
      lessThan(tester.getTopLeft(find.text('The Lord Is My Shepherd')).dy),
    );
    expect(find.text('Psalm 23'), findsOneWidget);
  });

  testWidgets('opens a reading', (tester) async {
    await pumpApp(tester, db, location: '/readings');

    await tester.tap(find.text('Benedictions'));
    await tester.pumpAndSettle();

    expect(find.byType(ReadingPage), findsOneWidget);
  });

  testWidgets('shows no cards when the book has no creed or covenant', (
    tester,
  ) async {
    await db.customStatement(
      "DELETE FROM readings WHERE kind IN ('creed', 'covenant')",
    );
    await pumpApp(tester, db, location: '/readings');

    expect(find.text('COVENANT'), findsNothing);
    expect(find.text('CREED'), findsNothing);
  });
}
