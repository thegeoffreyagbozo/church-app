import 'package:flutter_test/flutter_test.dart';
import 'package:notation/testing.dart';
import 'package:xml/xml.dart';

void main() {
  final doc = XmlDocument.parse(oldHundredth());

  test('two lines of four parts: 16 notes in each voice', () {
    expect(
      doc.findAllElements('note').where((n) => n.getElement('rest') == null),
      hasLength(64),
    );
  });

  test('carries a tie, a slur, a rest and a final double barline', () {
    expect(doc.findAllElements('tie'), hasLength(2)); // start and stop
    expect(doc.findAllElements('slur'), hasLength(2));
    expect(doc.findAllElements('rest'), hasLength(4)); // one per voice
    expect(doc.findAllElements('bar-style').single.innerText, 'light-heavy');
  });

  test('four verses of sixteen syllables', () {
    for (var verse = 1; verse <= 4; verse++) {
      expect(
        doc
            .findAllElements('lyric')
            .where((l) => l.getAttribute('number') == '$verse'),
        hasLength(16),
      );
    }
  });
}
