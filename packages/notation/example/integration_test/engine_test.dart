import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notation/notation.dart';
import 'package:notation/testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late NotationEngine engine;

  setUpAll(() async => engine = await NotationEngine.start());
  tearDownAll(() => engine.dispose());

  test('Verovio reports its version', () {
    expect(engine.verovioVersion, startsWith('6.3.0'));
  });

  test('draws every note of the four parts on one page', () async {
    final pages = await engine.render(oldHundredth(), width: 400, verse: 1);

    expect(pages, hasLength(1));
    expect(RegExp(r'class="note"').allMatches(pages.single), hasLength(32));
  });

  test('broken MusicXML throws, and the next drawing still works', () async {
    await expectLater(
      engine.render('<score-partwise><part', width: 400, verse: 1),
      throwsA(isA<NotationException>()),
    );

    final pages = await engine.render(oldHundredth(), width: 400, verse: 1);
    expect(pages, hasLength(1));
  });

  test('only the chosen verse is drawn', () async {
    final first = (await engine.render(oldHundredth(), width: 400, verse: 1)).single;
    final second = (await engine.render(oldHundredth(), width: 400, verse: 2)).single;

    expect(first, contains('dwell'));
    expect(first, isNot(contains('God')));
    expect(second, contains('God'));
    expect(second, isNot(contains('dwell')));
  });
}
