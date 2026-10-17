import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

void main() {
  final book = parseSources([
    const Source('b.txt', '''
SECTION Service Music
HYMN
Title: Doxology

Praise God, from whom all blessings flow;

SECTION Hymns
HYMN 267
Title: All Things Work Out for Good

1
All things work out for good.
'''),
  ]);

  test('reads one piece per row, skipping notes and blank lines', () {
    final issues = <Issue>[];
    final music = parseMusicMap(
      const Source(
        'm.tsv',
        '# a note\n\nHymns\t267\t1\thymns/267-1.png\t271\n'
            'Service Music\tDoxology\t1\tservice-music/doxology-1.png\t2\n',
      ),
      issues,
    );
    expect(issues, isEmpty);
    expect(
      [
        for (final m in music)
          '${m.section}|${m.key}|${m.part}|${m.path}|${m.page}',
      ],
      [
        'Hymns|267|1|hymns/267-1.png|271',
        'Service Music|Doxology|1|service-music/doxology-1.png|2',
      ],
    );
  });

  test('a row with the wrong number of columns is an error', () {
    final issues = <Issue>[];
    parseMusicMap(const Source('m.tsv', 'Hymns\t267\t1\n'), issues);
    expect(issues.single.toString(), startsWith('m.tsv:1: error:'));
  });

  test('a piece for a hymn the book lacks, or a gap in the parts, is an error',
      () {
    final issues = <Issue>[];
    final music = parseMusicMap(
      const Source(
        'm.tsv',
        'Hymns\t999\t1\thymns/999-1.png\t1\n'
            'Hymns\t267\t2\thymns/267-2.png\t272\n',
      ),
      issues,
    );
    expect([
      for (final i in checkMusicMap(book, music)) i.message,
    ], [
      'Hymns 999 is not in the batch files',
      'Hymns 267 has part 2 but no part 1',
    ]);
  });
}
