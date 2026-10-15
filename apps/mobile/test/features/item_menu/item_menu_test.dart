import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers text size, keep screen on, share and report', (
    tester,
  ) async {
    await pumpApp(tester, db, location: '/hymn/hymn-41');
    await openMenu(tester);

    expect(find.text('Text size and theme'), findsOneWidget);
    expect(find.text('Keep screen on'), findsOneWidget);
    expect(find.text('Share hymn'), findsOneWidget);
    expect(find.text('Report a mistake'), findsOneWidget);
  });

  testWidgets('text size and theme opens the reading settings', (tester) async {
    await pumpApp(tester, db, location: '/hymn/hymn-41');
    await openMenu(tester);

    await tester.tap(find.text('Text size and theme'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);
  });

  testWidgets('shares the words of a public-domain hymn', (tester) async {
    final platform = await pumpApp(tester, db, location: '/hymn/supp-2');
    await openMenu(tester);

    await tester.tap(find.text('Share hymn'));
    await tester.pumpAndSettle();

    final text = platform.sharing.shared.single;
    expect(
      text,
      startsWith('Supplementary 2 · Thine Is the Glory\n\nVerse 1\n'),
    );
    expect(text, contains('Refrain\nThine is the glory'));
    expect(text, endsWith('Shared from Grace Chapel'));
  });

  testWidgets('shares only the number and title of a protected hymn', (
    tester,
  ) async {
    final platform = await pumpApp(tester, db, location: '/hymn/hymn-7');
    await openMenu(tester);
    expect(find.text('Sends the number and title'), findsOneWidget);

    await tester.tap(find.text('Share hymn'));
    await tester.pumpAndSettle();

    expect(
      platform.sharing.shared.single,
      'Hymn 7 · A Modern Hymn\n\nShared from Grace Chapel',
    );
  });

  testWidgets('reports a mistake on WhatsApp when it is installed', (
    tester,
  ) async {
    final platform = TestPlatform()
      ..launcher = FakeLauncher(installed: {'whatsapp', 'mailto'});
    await pumpApp(tester, db, location: '/hymn/hymn-41', platform: platform);
    await openMenu(tester);

    await tester.tap(find.text('Report a mistake'));
    await tester.pumpAndSettle();

    final uri = platform.launcher.opened.single;
    expect(uri.scheme, 'whatsapp');
    expect(uri.queryParameters['phone'], '233200000000');
    expect(
      uri.queryParameters['text'],
      'Mistake in Hymn 41 · How Firm a Foundation: ',
    );
  });

  testWidgets('falls back to email without WhatsApp', (tester) async {
    final platform = TestPlatform()
      ..launcher = FakeLauncher(installed: {'mailto'});
    await pumpApp(tester, db, location: '/hymn/hymn-41', platform: platform);
    await openMenu(tester);

    await tester.tap(find.text('Report a mistake'));
    await tester.pumpAndSettle();

    final uri = platform.launcher.opened.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'hello@example.church');
  });

  testWidgets('copies the message when nothing can send it', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await pumpApp(tester, db, location: '/hymn/hymn-41');
    await openMenu(tester);

    await tester.tap(find.text('Report a mistake'));
    await tester.pumpAndSettle();

    expect(copied.single, 'Mistake in Hymn 41 · How Firm a Foundation: ');
    expect(
      find.text('Copied. Paste it into a message to Grace Chapel.'),
      findsOneWidget,
    );
  });

  testWidgets('hides report when the church has no contact', (tester) async {
    await db.customStatement(
      'UPDATE church SET email = NULL, phone = NULL, whatsapp = NULL',
    );
    await pumpApp(tester, db, location: '/hymn/hymn-41');
    await openMenu(tester);

    expect(find.text('Report a mistake'), findsNothing);
  });
}
