import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/features/hymnal/presentation/hymn_page.dart';
import 'package:church_app/startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The pew flow on a phone or emulator with the real bundled hymn book, timed against
/// the speed targets (spec section 8). Uninstall the app first for a first launch, and
/// run in profile mode (see apps/mobile/README.md). Timings are saved to
/// build/integration_response_data.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps frames until [finder] finds something; returns how long that took.
  Future<int> millisecondsUntil(WidgetTester tester, Finder finder) async {
    final watch = Stopwatch()..start();
    while (finder.evaluate().isEmpty) {
      if (watch.elapsed > const Duration(seconds: 10)) {
        fail('Timed out waiting for $finder');
      }
      await tester.pump(const Duration(milliseconds: 4));
    }
    return watch.elapsedMilliseconds;
  }

  testWidgets('a hymn number opens its hymn within the targets', (
    tester,
  ) async {
    // The integration binding leaves the phone's keyboard connected; route the search
    // field to the test keyboard so the test can type the number and press Go.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await tester.pumpWidget(const StartupApp());
    final home = await millisecondsUntil(tester, find.byType(TextField));

    // The first number of the default section, whichever book is bundled.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TextField)),
    );
    final section = await container.read(catalogProvider).defaultSection();
    final number = section!.lowestNumber!;

    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.enterText('$number');
    final search = await millisecondsUntil(
      tester,
      find.text('Press Go to open'),
    );

    await tester.testTextInput.receiveAction(TextInputAction.go);
    final open = await millisecondsUntil(tester, find.byType(HymnPage));

    binding.reportData = {
      'home_after_first_frame_ms': home,
      'search_ms': search,
      'open_hymn_ms': open,
    };
    expect(search, lessThan(100), reason: 'search results within 100 ms');
    expect(open, lessThan(300), reason: 'a hymn opens within 300 ms');
  });
}
