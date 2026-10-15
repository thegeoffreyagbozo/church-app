import 'package:church_app/features/readings/presentation/readings_screen.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets('the tab bar switches between Hymns and Readings', (
    tester,
  ) async {
    await pumpApp(tester, db);

    await tester.tap(find.text('Readings'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingsScreen), findsOneWidget);

    await tester.tap(find.text('Hymns'));
    await tester.pumpAndSettle();
    expect(find.text('Grace Chapel'), findsOneWidget);
  });

  testWidgets('the tab bar hides while the keyboard is up', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
