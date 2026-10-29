import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/parts.dart';
import 'package:xml/xml.dart';

/// Two staves as Verovio draws them with `svgAdditionalAttribute` staff@n and layer@n.
/// [bottom] gives the bottom staff's layer numbers (1 and 2, or MuseScore's 5 and 6).
String _svg({List<int> bottom = const [1, 2]}) => '''
<svg><g class="system">
  <g class="staff" data-n="1">
    <g class="layer" data-n="1"><g class="note"/><g class="verse"><text>All</text></g></g>
    <g class="layer" data-n="2"><g class="note"/></g>
  </g>
  <g class="staff" data-n="2">
    <g class="layer" data-n="${bottom[0]}"><g class="note"/></g>
    <g class="layer" data-n="${bottom[1]}"><g class="note"/></g>
  </g>
</g></svg>''';

Map<String, String?> _opacity(String svg) {
  final doc = XmlDocument.parse(svg);
  final result = <String, String?>{};
  for (final staff in doc.findAllElements('g').where((g) => g.getAttribute('class') == 'staff')) {
    for (final layer in staff.findElements('g')) {
      result['${staff.getAttribute('data-n')}/${layer.getAttribute('data-n')}'] =
          layer.getAttribute('fill-opacity');
    }
  }
  return result;
}

void main() {
  test('fades every voice but the chosen one', () {
    expect(_opacity(fadeOtherParts(_svg(), Part.alto)), {
      '1/1': '0.35',
      '1/2': null,
      '2/1': '0.35',
      '2/2': '0.35',
    });
  });

  test('strokes fade with the fill', () {
    final doc = XmlDocument.parse(fadeOtherParts(_svg(), Part.bass));
    final soprano = doc.findAllElements('g').firstWhere(
      (g) => g.getAttribute('data-n') == '1' && g.getAttribute('class') == 'layer',
    );
    expect(soprano.getAttribute('stroke-opacity'), '0.35');
  });

  test('the words under a faded soprano stay in full ink', () {
    final doc = XmlDocument.parse(fadeOtherParts(_svg(), Part.tenor));
    final verse = doc.findAllElements('g').firstWhere((g) => g.getAttribute('class') == 'verse');

    expect(verse.getAttribute('fill-opacity'), '1');
    expect(verse.getAttribute('stroke-opacity'), '1');
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
    const svg = '<svg><g class="staff"><g class="layer"><g class="note"/></g></g></svg>';

    expect(fadeOtherParts(svg, Part.soprano), XmlDocument.parse(svg).toXmlString());
  });
}
