import 'package:church_app/features/readings/presentation/readings_screen.dart';
import 'package:church_app/features/settings/presentation/settings_screen.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/cupertino.dart';
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

  testWidgets('the Settings tab opens settings', (tester) async {
    await pumpApp(tester, db);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
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

  /// A 393 x 852 phone.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('on Android the tab bar runs the full width of the bottom edge', (
    tester,
  ) async {
    phone(tester);
    await pumpApp(tester, db);

    final bar = tester.getRect(find.byType(NavigationBar));
    expect(bar.left, 0);
    expect(bar.right, 393);
    expect(bar.bottom, 852);
  });

  testWidgets('the end of a list scrolls clear of the tab bar', (tester) async {
    phone(tester);
    await pumpApp(tester, db, location: '/settings');

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final barTop = tester.getRect(find.byType(NavigationBar)).top;
    expect(tester.getRect(find.text('Licences')).bottom, lessThan(barTop));
  });

  testWidgets('on iPhone the tab bar is the iOS one', (tester) async {
    await pumpApp(tester, db);
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Readings'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingsScreen), findsOneWidget);

    await tester.tap(find.text('Hymns'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoTabBar), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
