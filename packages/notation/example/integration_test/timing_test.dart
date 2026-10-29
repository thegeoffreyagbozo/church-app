import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notation/notation.dart';
import 'package:notation/testing.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('a four-verse hymn draws within the go/no-go targets', () async {
    final watch = Stopwatch()..start();
    final engine = await NotationEngine.start();
    final startMs = watch.elapsedMilliseconds;

    watch.reset();
    await engine.render(
      oldHundredth(),
      width: 400,
      verse: 1,
      part: Part.soprano,
    );
    final firstMs = watch.elapsedMilliseconds;

    watch.reset();
    await engine.render(
      oldHundredth(),
      width: 400,
      verse: 2,
      part: Part.soprano,
    );
    final otherVerseMs = watch.elapsedMilliseconds;

    watch.reset();
    await engine.render(
      oldHundredth(),
      width: 400,
      verse: 1,
      part: Part.soprano,
    );
    final cachedMs = watch.elapsedMilliseconds;
    await engine.dispose();

    binding.reportData = {
      'engine_start_ms': startMs,
      'first_draw_ms': firstMs,
      'other_verse_ms': otherVerseMs,
      'cached_draw_ms': cachedMs,
    };
    // ignore: avoid_print
    print(
      'start $startMs ms, first $firstMs ms, other verse $otherVerseMs ms, '
      'cached $cachedMs ms',
    );
    expect(firstMs, lessThan(300));
    expect(cachedMs, lessThan(16));
  });
}
