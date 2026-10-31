import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

const _score = '''
<score-partwise><part id="P1">
<measure number="1">
<attributes><staves>2</staves></attributes>
<note><voice>1</voice><staff>1</staff>
  <lyric number="1"><syllabic>begin</syllabic><text>Bless</text></lyric>
  <lyric number="2"><syllabic>single</syllabic><text>Sing</text></lyric></note>
<note><voice>1</voice><staff>1</staff>
  <lyric number="1"><syllabic>end</syllabic><text>ing</text></lyric>
  <lyric number="2"><syllabic>single</syllabic><text>praise</text></lyric></note>
<note><voice>2</voice><staff>1</staff></note>
<note><voice>5</voice><staff>2</staff></note>
<note><voice>6</voice><staff>2</staff></note>
</measure></part></score-partwise>''';

List<int> _mxl(String xml, {String root = 'score.musicxml'}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'META-INF/container.xml',
        '<container><rootfiles><rootfile full-path="$root"/></rootfiles></container>',
      ),
    )
    ..addFile(ArchiveFile.string(root, xml));
  return ZipEncoder().encode(archive);
}

void main() {
  group('musicXmlFromFile', () {
    test('reads the root file a .mxl names', () {
      expect(musicXmlFromFile(_mxl(_score)), _score);
    });

    test('takes plain MusicXML as it is', () {
      expect(musicXmlFromFile(utf8.encode(_score)), _score);
    });

    test('a .mxl without its root file is an error', () {
      final broken = ZipEncoder().encode(
        Archive()
          ..addFile(
            ArchiveFile.string(
              'META-INF/container.xml',
              '<container><rootfiles><rootfile full-path="x.musicxml"/></rootfiles></container>',
            ),
          ),
      );
      expect(
        () => musicXmlFromFile(broken),
        throwsA(isA<NotationFileException>()),
      );
    });
  });

  group('readNotationFacts', () {
    final facts = readNotationFacts(_score);

    test('counts the staves', () => expect(facts.staves, 2));

    test("lists each staff's voices", () {
      expect(facts.voices, {
        1: {1, 2},
        2: {5, 6},
      });
    });

    test("lists the verses and joins each verse's syllables", () {
      expect(facts.verses, [1, 2]);
      expect(facts.words, {1: 'Blessing', 2: 'Sing praise'});
    });

    test('text that is not XML is an error', () {
      expect(
        () => readNotationFacts('not xml'),
        throwsA(isA<NotationFileException>()),
      );
    });
  });
}
