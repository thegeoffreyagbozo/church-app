import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dy;

  testWidgets('a grouped section heads its hymns with the book\'s titles', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester, db, location: '/section/section-hymns');

    expect(find.text('I. HYMNS OF WORSHIP'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('II. THE HOLY SPIRIT'), findsOneWidget);
    expect(find.text('Songs of Assurance and Trust'), findsOneWidget);
    expect(
      top(tester, 'Amazing Grace'),
      lessThan(top(tester, 'II. THE HOLY SPIRIT')),
    );
    expect(
      top(tester, 'II. THE HOLY SPIRIT'),
      lessThan(top(tester, 'A Modern Hymn')),
    );
  });

  testWidgets('Contents lists the parts and jumps to the last subheading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, db, location: '/section/section-hymns');
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, 0);

    await tester.tap(find.byTooltip('Contents'));
    await tester.pumpAndSettle();
    expect(find.text('I. Hymns of Worship'), findsOneWidget);
    expect(find.text('III. The Christian Experience'), findsOneWidget);
    await tester.tap(find.text('Songs of Assurance and Trust').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(position.pixels, greaterThan(0));
    expect(
      find.text('Songs of Assurance and Trust').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('a section without contents headings has no Contents button', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/section/section-supplementary');

    expect(find.byTooltip('Contents'), findsNothing);
  });
}
