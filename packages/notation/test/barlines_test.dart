import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/barlines.dart';
import 'package:xml/xml.dart';

List<String> _barlinePaths(String svg) => [
  for (final path in XmlDocument.parse(svg).findAllElements('path'))
    path.getAttribute('d')!,
];

void main() {
  test('drops the piece that joins two staves, keeping each staff\'s own', () {
    const svg =
        '<svg><g class="barLine">'
        '<path d="M6109 540 L6109 1260" stroke-width="27"/>'
        '<path d="M6109 2983 L6109 3703" stroke-width="27"/>'
        '<path d="M6109 1260 L6109 2983" stroke-width="27"/>'
        '</g></svg>';

    expect(_barlinePaths(breakBarlinesBetweenStaves(svg)), [
      'M6109 540 L6109 1260',
      'M6109 2983 L6109 3703',
    ]);
  });

  test('a thick and a thin line at the end each lose only their own join', () {
    const svg =
        '<svg><g class="barLine">'
        '<path d="M100 0 L100 10"/><path d="M100 20 L100 30"/>'
        '<path d="M100 10 L100 20"/>'
        '<path d="M120 0 L120 10"/><path d="M120 20 L120 30"/>'
        '<path d="M120 10 L120 20"/>'
        '</g></svg>';

    expect(_barlinePaths(breakBarlinesBetweenStaves(svg)), [
      'M100 0 L100 10',
      'M100 20 L100 30',
      'M120 0 L120 10',
      'M120 20 L120 30',
    ]);
  });

  test('lines outside barlines, such as the system\'s opening line, stay', () {
    const svg =
        '<svg><g class="system"><path d="M10 0 L10 10"/>'
        '<path d="M10 20 L10 30"/><path d="M10 10 L10 20"/></g></svg>';

    expect(_barlinePaths(breakBarlinesBetweenStaves(svg)), hasLength(3));
  });
}
