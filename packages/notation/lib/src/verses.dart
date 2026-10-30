import 'package:xml/xml.dart';

/// The verse a MusicXML lyric belongs to; a lyric with no number is verse 1.
int _verseOf(XmlElement lyric) =>
    int.tryParse(lyric.getAttribute('number') ?? '') ?? 1;

/// The number of verses: the highest lyric number, or 0 when there are no words.
int verseCount(String musicXml) {
  final lyrics = XmlDocument.parse(musicXml).findAllElements('lyric');
  return lyrics.fold(
    0,
    (most, lyric) => _verseOf(lyric) > most ? _verseOf(lyric) : most,
  );
}

/// [musicXml] with only [verse]'s words left under the notes, numbered as verse 1.
///
/// A refrain is often written once, as verse 1 only. So in a bar where the chosen verse
/// has no words of its own, verse 1's words stay, as long as the hymn has that verse at
/// all. Bars are the unit, so a verse that holds one syllable over several notes doesn't
/// pick up verse 1's syllables in between.
String keepVerse(String musicXml, int verse) {
  if (verse < 1) throw ArgumentError.value(verse, 'verse', 'starts at 1');
  final document = XmlDocument.parse(musicXml);
  final hasVerse = document
      .findAllElements('lyric')
      .any((l) => _verseOf(l) == verse);
  final measures = document.findAllElements('measure').toList();
  for (final XmlNode bar in measures.isEmpty ? [document] : measures) {
    final lyrics = bar.findAllElements('lyric').toList();
    final ownWords = lyrics.any((l) => _verseOf(l) == verse);
    final borrowed = hasVerse && !ownWords ? 1 : verse;
    for (final lyric in lyrics) {
      if (_verseOf(lyric) != borrowed) {
        lyric.remove();
      } else {
        // Verovio gives each verse number its own row; as verse 1 it sits right under
        // the top staff instead of below empty rows.
        lyric.setAttribute('number', '1');
      }
    }
  }
  return document.toXmlString();
}
