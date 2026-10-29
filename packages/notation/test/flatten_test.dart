import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/flatten.dart';
import 'package:xml/xml.dart';

/// The shape of Verovio's output: an outer page size and an inner, scaled drawing.
const _verovio = '''
<svg width="400px" height="344px" xmlns="http://www.w3.org/2000/svg" id="p1">
  <defs><g id="E0A4-p1"><path d="M0 0 L1 1"/></g></defs>
  <style type="text/css">#p1 path {stroke:currentColor}</style>
  <svg class="definition-scale" color="black" font-family="Times, serif" viewBox="0 0 10000 8600">
    <g class="page-margin" transform="translate(200, 200)"><use xlink:href="#E0A4-p1"/></g>
  </svg>
</svg>''';

void main() {
  test(
    'the inner svg becomes a group scaled from its viewBox to the page size',
    () {
      final root = XmlDocument.parse(flattenForFlutter(_verovio)).rootElement;

      expect(root.findAllElements('svg'), isEmpty);
      final group = root.findElements('g').single;
      expect(group.getAttribute('transform'), 'scale(0.04 0.04)');
      expect(group.getAttribute('color'), 'black');
      expect(
        group.getAttribute('font-family'),
        tinosFamily,
      ); // Times' letter widths, which Verovio spaces the words by
      expect(
        group.findElements('g').single.getAttribute('class'),
        'page-margin',
      );
    },
  );

  test(
    'lines take their colour from the drawing, since flutter_svg ignores <style>',
    () {
      final root = XmlDocument.parse(flattenForFlutter(_verovio)).rootElement;

      expect(root.findElements('style'), isEmpty);
      expect(
        root.findElements('g').single.getAttribute('stroke'),
        'currentColor',
      );
    },
  );

  test('a drawing without an inner svg is left as it is', () {
    const svg = '<svg width="10px" height="10px"><path d="M0 0"/></svg>';

    expect(flattenForFlutter(svg), XmlDocument.parse(svg).toXmlString());
  });

  test(
    'a syllable carries its size already scaled, since flutter_svg does not scale text',
    () {
      const svg = '''
<svg width="400px" height="344px"><svg viewBox="0 0 10000 8600"><g class="syl">
  <text x="3107" y="2301" font-size="0px">
    <tspan class="text"><tspan font-size="405px">All</tspan></tspan>
  </text>
</g></svg></svg>''';

      final text = XmlDocument.parse(
        flattenForFlutter(svg),
      ).findAllElements('text').single;

      expect(
        text.getAttribute('font-size'),
        '16.2px',
      ); // 405 at the page's 0.04
      expect(text.getAttribute('x'), '3107');
      expect(
        text.getAttribute('stroke'),
        'none',
      ); // the group's line colour would embolden it
      expect(text.childElements, isEmpty);
      expect(text.innerText, 'All');
    },
  );

  test('the part name Verovio prints before the first line is left out', () {
    const svg = '''
<svg width="400px" height="344px"><svg viewBox="0 0 10000 8600">
  <g class="label"><text font-size="0px"><tspan><tspan font-size="405px">Choir</tspan></tspan></text></g>
  <g class="note"/>
</svg></svg>''';

    final out = flattenForFlutter(svg);

    expect(out, isNot(contains('Choir')));
    expect(out, contains('class="note"'));
  });
}
