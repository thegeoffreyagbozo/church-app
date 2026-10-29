import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/parts.dart';
import 'package:xml/xml.dart';

/// Two staves as Verovio draws them with `svgAdditionalAttribute` staff@n and
/// layer@n: each note is a glyph and a stem; the soprano's note also carries a
/// verse (a syllable and the hyphen after it). [bottom] gives the bottom staff's
/// layer numbers (1 and 2, or MuseScore's 5 and 6).
String _svg({List<int> bottom = const [1, 2]}) {
  String layer(int n, {bool words = false}) =>
      '<g class="layer" data-n="$n"><g class="note"><use/><path d="M0 0"/>'
      '${words ? '<g class="verse"><text>All</text><rect/></g>' : ''}</g></g>';
  return '<svg><g class="system">'
      '<g class="staff" data-n="1">${layer(1, words: true)}${layer(2)}</g>'
      '<g class="staff" data-n="2">${layer(bottom[0])}${layer(bottom[1])}</g>'
      '</g></svg>';
}

Iterable<XmlElement> _layers(String svg) => XmlDocument.parse(
  svg,
).findAllElements('g').where((g) => g.getAttribute('class') == 'layer');

/// Each voice's glyph opacity, keyed staff/layer.
Map<String, String?> _opacity(String svg) => {
  for (final layer in _layers(svg))
    '${layer.parentElement!.getAttribute('data-n')}/${layer.getAttribute('data-n')}':
        layer.findAllElements('use').single.getAttribute('fill-opacity'),
};

void main() {
  test('fades every voice but the chosen one', () {
    expect(_opacity(fadeOtherParts(_svg(), Part.alto)), {
      '1/1': '0.35',
      '1/2': null,
      '2/1': '0.35',
      '2/2': '0.35',
    });
  });

  test('stems and other lines fade with the note heads', () {
    final soprano = _layers(fadeOtherParts(_svg(), Part.bass)).first;

    expect(
      soprano.findAllElements('path').single.getAttribute('stroke-opacity'),
      '0.35',
    );
  });

  test('the words under a faded soprano stay in full ink', () {
    final soprano = _layers(fadeOtherParts(_svg(), Part.tenor)).first;
    final verse = soprano
        .findAllElements('g')
        .firstWhere((g) => g.getAttribute('class') == 'verse');

    // Opacity is set on the shapes, never on a group above the words, because
    // flutter_svg multiplies a child's opacity instead of letting it override.
    expect(soprano.getAttribute('fill-opacity'), isNull);
    for (final shape in verse.descendantElements) {
      expect(shape.getAttribute('fill-opacity'), isNull);
      expect(shape.getAttribute('stroke-opacity'), isNull);
    }
  });

  test('works when the bottom staff numbers its voices 5 and 6', () {
    expect(_opacity(fadeOtherParts(_svg(bottom: [5, 6]), Part.tenor)), {
      '1/1': '0.35',
      '1/2': '0.35',
      '2/5': null,
      '2/6': '0.35',
    });
  });

  test('a drawing without voice numbers is left as it is', () {
    const svg =
        '<svg><g class="staff"><g class="layer"><g class="note"/></g></g></svg>';

    expect(
      fadeOtherParts(svg, Part.soprano),
      XmlDocument.parse(svg).toXmlString(),
    );
  });
}
