import 'package:xml/xml.dart';

/// The verse a MusicXML lyric belongs to; a lyric with no number is verse 1.
int _verseOf(XmlElement lyric) => int.tryParse(lyric.getAttribute('number') ?? '') ?? 1;

/// The number of verses: the highest lyric number, or 0 when there are no words.
int verseCount(String musicXml) {
  final lyrics = XmlDocument.parse(musicXml).findAllElements('lyric');
  return lyrics.fold(0, (most, lyric) => _verseOf(lyric) > most ? _verseOf(lyric) : most);
}

/// [musicXml] with only [verse]'s words left under the notes.
String keepVerse(String musicXml, int verse) {
  if (verse < 1) throw ArgumentError.value(verse, 'verse', 'starts at 1');
  final document = XmlDocument.parse(musicXml);
  for (final lyric in document.findAllElements('lyric').toList()) {
    if (_verseOf(lyric) != verse) lyric.remove();
  }
  return document.toXmlString();
}
