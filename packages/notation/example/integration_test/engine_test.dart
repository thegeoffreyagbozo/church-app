import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notation/notation.dart';
import 'package:notation/testing.dart';
import 'package:xml/xml.dart';

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
    final first = (await engine.render(
      oldHundredth(),
      width: 400,
      verse: 1,
    )).single;
    final second = (await engine.render(
      oldHundredth(),
      width: 400,
      verse: 2,
    )).single;

    expect(first, contains('dwell'));
    expect(first, isNot(contains('God')));
    expect(second, contains('God'));
    expect(second, isNot(contains('dwell')));
  });

  test('Verovio numbers staves and voices so parts can be faded', () async {
    final svg = (await engine.render(
      oldHundredth(),
      width: 400,
      verse: 1,
      part: Part.alto,
    )).single;
    final heads = XmlDocument.parse(svg)
        .findAllElements('g')
        .where(
          (g) =>
              (g.getAttribute('class') ?? '').split(' ').contains('notehead'),
        )
        .map((g) => g.findElements('use').first.getAttribute('fill-opacity'))
        .toList();

    expect(heads.where((o) => o == '$fadedOpacity'), hasLength(24)); // S, T, B
    expect(heads.where((o) => o == null), hasLength(8)); // the alto
  });

  test('the words stay in full ink when the soprano is faded', () async {
    final svg = (await engine.render(
      oldHundredth(),
      width: 400,
      verse: 1,
      part: Part.bass,
    )).single;
    final verses = XmlDocument.parse(svg)
        .findAllElements('g')
        .where(
          (g) => (g.getAttribute('class') ?? '').split(' ').contains('verse'),
        );

    expect(verses, isNotEmpty);
    for (final verse in verses) {
      for (final element in [verse, ...verse.descendantElements]) {
        expect(element.getAttribute('fill-opacity'), isNull);
      }
    }
  });

  test('renders sent back to back each get their own drawing', () async {
    final results = await Future.wait([
      engine.render(oldHundredth(), width: 400, verse: 1),
      engine.render(oldHundredth(), width: 400, verse: 2),
      engine.render(oldHundredth(), width: 400, verse: 3),
    ]);

    expect(results[0].single, contains('dwell'));
    expect(results[1].single, contains('God'));
    expect(results[2].single, contains('gates'));
  });

  test('a repeat drawing comes from the cache', () async {
    final first = await engine.render(
      oldHundredth(),
      width: 360,
      verse: 4,
      part: Part.bass,
    );
    final again = await engine.render(
      oldHundredth(),
      width: 360,
      verse: 4,
      part: Part.bass,
    );

    expect(identical(first, again), isTrue);
  });

  test(
    'drawings come out in a shape flutter_svg can draw (no nested svg)',
    () async {
      final svg = (await engine.render(
        oldHundredth(),
        width: 400,
        verse: 1,
      )).single;

      expect(
        XmlDocument.parse(svg).rootElement.findAllElements('svg'),
        isEmpty,
      );
    },
  );
}
