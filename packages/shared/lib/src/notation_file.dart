import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// A notation file that can't be read as MusicXML.
class NotationFileException implements Exception {
  const NotationFileException(this.message);

  final String message;

  @override
  String toString() => 'NotationFileException: $message';
}

/// The MusicXML in [bytes]: the root file of a compressed `.mxl` (named by its
/// `META-INF/container.xml`), or the bytes as text when they are plain MusicXML.
String musicXmlFromFile(List<int> bytes) {
  final isZip = bytes.length > 1 && bytes[0] == 0x50 && bytes[1] == 0x4b;
  if (!isZip) return _text(bytes);
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw NotationFileException('not a readable .mxl: $e');
  }
  final container = archive.findFile('META-INF/container.xml');
  final root = container == null
      ? null
      : _parse(_text(container.readBytes()!))
          .findAllElements('rootfile')
          .firstOrNull
          ?.getAttribute('full-path');
  if (root == null) {
    throw const NotationFileException('the .mxl names no root file');
  }
  final file = archive.findFile(root);
  if (file == null) {
    throw NotationFileException('$root is missing from the .mxl');
  }
  return _text(file.readBytes()!);
}

String _text(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    throw const NotationFileException('not UTF-8 text');
  }
}

/// What the app and the import check need to know about a hymn's MusicXML.
class NotationFacts {
  const NotationFacts({
    required this.staves,
    required this.voices,
    required this.verses,
    required this.words,
  });

  /// The number of staves (`<staves>`), 1 when the file doesn't say.
  final int staves;

  /// Each staff's voice numbers, as the file numbers them.
  final Map<int, Set<int>> voices;

  /// The verse numbers that have words, in order.
  final List<int> verses;

  /// Each verse's words, its syllables joined as they are sung.
  final Map<int, String> words;
}

XmlDocument _parse(String xml) {
  try {
    return XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw NotationFileException('not XML: ${e.message}');
  }
}

int _number(XmlElement? element, int fallback) =>
    int.tryParse(element?.innerText.trim() ?? '') ?? fallback;

/// Reads [musicXml]'s staves, voices and words.
NotationFacts readNotationFacts(String musicXml) {
  final document = _parse(musicXml);
  var staves = 1;
  for (final s in document.findAllElements('staves')) {
    final n = _number(s, 1);
    if (n > staves) staves = n;
  }
  final voices = <int, Set<int>>{};
  final words = <int, StringBuffer>{};
  for (final note in document.findAllElements('note')) {
    final staff = _number(note.getElement('staff'), 1);
    final voice = _number(note.getElement('voice'), 1);
    (voices[staff] ??= {}).add(voice);
    for (final lyric in note.findElements('lyric')) {
      final verse = int.tryParse(lyric.getAttribute('number') ?? '1');
      if (verse == null) continue;
      final text = lyric.getElement('text')?.innerText ?? '';
      final syllabic = lyric.getElement('syllabic')?.innerText ?? 'single';
      final joined = syllabic == 'begin' || syllabic == 'middle';
      (words[verse] ??= StringBuffer()).write(joined ? text : '$text ');
    }
  }
  return NotationFacts(
    staves: staves,
    voices: voices,
    verses: words.keys.toList()..sort(),
    words: {
      for (final MapEntry(:key, :value) in words.entries)
        key: value.toString().trim(),
    },
  );
}
