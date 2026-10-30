import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/verses.dart';
import 'package:notation/testing.dart';
import 'package:xml/xml.dart';

List<String> _words(String musicXml) => [
  for (final text in XmlDocument.parse(musicXml).findAllElements('text'))
    text.innerText,
];

void main() {
  test('counts the verses', () {
    expect(verseCount(oldHundredth()), 4);
  });

  test('keeps only the chosen verse', () {
    final words = _words(keepVerse(oldHundredth(), 2));

    expect(words, [
      ...['The', 'Lord', 'ye', 'know', 'is', 'God', 'in', 'deed'],
      ...['With', 'out', 'our', 'aid', 'he', 'did', 'us', 'make'],
    ]);
  });

  test('a lyric with no number counts as verse 1', () {
    const xml =
        '<score-partwise><note><lyric><text>Hal</text></lyric>'
        '<lyric number="2"><text>Glo</text></lyric></note></score-partwise>';

    expect(_words(keepVerse(xml, 1)), ['Hal']);
    expect(verseCount(xml), 2);
  });

  test('a verse the file does not have leaves the notes with no words', () {
    final xml = keepVerse(oldHundredth(), 9);

    expect(_words(xml), isEmpty);
    expect(
      XmlDocument.parse(
        xml,
      ).findAllElements('note').where((n) => n.getElement('rest') == null),
      hasLength(64),
    );
  });

  test('a file with no words has no verses', () {
    expect(verseCount('<score-partwise><note/></score-partwise>'), 0);
  });

  test('verse numbers start at 1', () {
    expect(() => keepVerse(oldHundredth(), 0), throwsArgumentError);
  });

  test(
    'the kept verse becomes verse 1, so it sits in the first row of words',
    () {
      final lyrics = XmlDocument.parse(
        keepVerse(oldHundredth(), 4),
      ).findAllElements('lyric');

      expect(lyrics, hasLength(16));
      expect(lyrics.map((l) => l.getAttribute('number')).toSet(), {'1'});
    },
  );

  group('a refrain written once, as verse 1', () {
    // Bar 1 has words for verses 1 to 3; bar 2, the refrain, only for verse 1.
    const hymn =
        '<score-partwise><part>'
        '<measure number="1"><note>'
        '<lyric number="1"><text>One</text></lyric>'
        '<lyric number="2"><text>Two</text></lyric>'
        '<lyric number="3"><text>Three</text></lyric>'
        '</note></measure>'
        '<measure number="2"><note>'
        '<lyric number="1"><text>Glory</text></lyric>'
        '</note></measure>'
        '</part></score-partwise>';

    test('is sung after every verse', () {
      expect(_words(keepVerse(hymn, 3)), ['Three', 'Glory']);
    });

    test('is not borrowed in a bar the verse has its own words for', () {
      expect(_words(keepVerse(hymn, 2)), ['Two', 'Glory']);
    });

    test('is not added for a verse the hymn does not have', () {
      expect(_words(keepVerse(hymn, 9)), isEmpty);
    });
  });
}
