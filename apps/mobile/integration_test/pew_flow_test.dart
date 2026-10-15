import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/features/hymnal/presentation/hymn_text_block.dart';
import 'package:church_app/features/search/data/search_providers.dart';
import 'package:church_app/startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The pew flow on a phone or emulator with the real bundled hymn book, timed against
/// the speed targets (spec section 8): a number search, the hymn opening until its
/// words show, and a word typed one letter at a time. Uninstall the app first for a
/// first launch, and run in profile mode (see apps/mobile/README.md). The timings are
/// printed, and saved to build/integration_response_data.json when the targets hold.
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

  testWidgets('a hymn number and a typed word find hymns within the targets', (
    tester,
  ) async {
    // The integration binding leaves the phone's keyboard connected; route the search
    // field to the test keyboard so the test can type and press Go.
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
    final searchNumber = await millisecondsUntil(
      tester,
      find.text('Press Go to open'),
    );
    final hymn = (await container.read(
      searchResultsProvider.future,
    )).hits.first;

    await tester.testTextInput.receiveAction(TextInputAction.go);
    final open = await millisecondsUntil(tester, find.byType(HymnTextBlock));

    // Back on Home, type the longest word of that hymn's title one letter at a time,
    // as a reader would, and time the last letter until its results are drawn.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final word = (hymn.title.split(
      RegExp('[^A-Za-z]+'),
    )..sort((a, b) => b.length.compareTo(a.length))).first;
    await tester.showKeyboard(find.byType(TextField));
    for (var i = 1; i < word.length; i++) {
      tester.testTextInput.enterText(word.substring(0, i));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final watch = Stopwatch()..start();
    tester.testTextInput.enterText(word);
    final results = await container.read(searchResultsProvider.future);
    await tester.pump();
    final searchWord = watch.elapsedMilliseconds;

    final timings = {
      'home_after_first_frame_ms': home,
      'search_number_ms': searchNumber,
      'open_hymn_ms': open,
      'search_word_ms': searchWord,
    };
    binding.reportData = timings;
    debugPrint('Pew flow timings: $timings');
    expect(results.hits, isNotEmpty, reason: '"$word" finds its hymn');
    expect(searchNumber, lessThan(100), reason: 'number results within 100 ms');
    expect(searchWord, lessThan(100), reason: 'word results within 100 ms');
    expect(open, lessThan(300), reason: 'a hymn shows its words within 300 ms');
  });
}
