import 'package:church_app/features/home/presentation/home_screen.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

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
    expect(
      find.text('Hymns and readings you open will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('lists sections in book order', (tester) async {
    await pumpApp(tester, db);

    final service = tester.getTopLeft(onHome('Service Music'));
    final hymns = tester.getTopLeft(onHome('Hymns'));
    expect(service.dy < hymns.dy || service.dx < hymns.dx, isTrue);
  });

  testWidgets('a numbered section lists its hymns by number', (tester) async {
    await pumpApp(tester, db);

    await tester.tap(onHome('Hymns'));
    await tester.pumpAndSettle();

    final numbers = [
      '1',
      '2',
      '7',
      '41',
    ].map((n) => tester.getTopLeft(find.text(n)).dy);
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
