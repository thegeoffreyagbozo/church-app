import 'dart:convert';

import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

/// Two staves, voices 1/2 and 5/6, and the given verses as one note each.
String _score(Map<int, String> verses, {int staves = 2, bool alto = true}) {
  final lyrics = [
    for (final MapEntry(:key, :value) in verses.entries)
      '<lyric number="$key"><syllabic>single</syllabic><text>$value</text></lyric>',
  ].join();
  return '<score-partwise><part id="P1"><measure number="1">'
      '<attributes><staves>$staves</staves></attributes>'
      '<note><voice>1</voice><staff>1</staff>$lyrics</note>'
      '${alto ? '<note><voice>2</voice><staff>1</staff></note>' : ''}'
      '<note><voice>5</voice><staff>2</staff></note>'
      '<note><voice>6</voice><staff>2</staff></note>'
      '</measure></part></score-partwise>';
}

Book _book() => parseSources(
      [
        const Source('batch.txt', '''
SECTION Service Music
HYMN
Title: Doxology

Praise God amen

SECTION Hymns
HYMN 8
Title: All People

1
All people

2
Know that
'''),
      ],
      defaultSection: 'Hymns',
    );

List<Issue> _check(Map<String, String> files, String map) {
  final issues = <Issue>[];
  final entries = parseNotationMap(Source('notation.tsv', map), '/n', issues);
  return issues
    ..addAll(
      checkNotation(
        _book(),
        entries,
        file: 'notation.tsv',
        read: (path) => utf8.encode(files[path]!),
      ),
    );
}

void main() {
  test('a map row is section, number or title, and a file beside the map', () {
    final issues = <Issue>[];
    final entries = parseNotationMap(
      const Source('notation.tsv', '# notes\nHymns\t8\t008.mxl\n'),
      '/n',
      issues,
    );
    expect(issues, isEmpty);
    expect(entries.single.file, '/n/008.mxl');
    expect(entries.single.hymnKey, 'Hymns/8');
  });

  test('a well-made file with matching words passes', () {
    expect(
      _check(
        {
          '/n/008.mxl': _score({1: 'All people', 2: 'Know that'}),
        },
        'Hymns\t8\t008.mxl',
      ),
      isEmpty,
    );
  });

  test('an unnumbered hymn is found by its title', () {
    expect(
      _check(
        {
          '/n/dox.mxl': _score({1: 'Praise God amen'}),
        },
        'Service Music\tDoxology\tdox.mxl',
      ),
      isEmpty,
    );
  });

  test('one staff is an error', () {
    final issues = _check(
      {
        '/n/008.mxl': _score({1: 'All people'}, staves: 1),
      },
      'Hymns\t8\t008.mxl',
    );
    expect(issues.single.isError, isTrue);
    expect(issues.single.message, contains('2 staves'));
  });

  test('a staff with one voice is an error', () {
    final issues = _check(
      {
        '/n/008.mxl': _score({1: 'All people', 2: 'Know that'}, alto: false),
      },
      'Hymns\t8\t008.mxl',
    );
    expect(issues.single.message, contains('staff 1 has 1 voice'));
  });

  test('verses that skip a number are an error', () {
    final issues = _check(
      {
        '/n/008.mxl': _score({1: 'All people', 3: 'Know that'}),
      },
      'Hymns\t8\t008.mxl',
    );
    expect(issues.single.message, contains('verses 1, 3'));
  });

  test('words that differ from the batch are a warning, not an error', () {
    final issues = _check(
      {
        '/n/008.mxl': _score({1: 'All peoples', 2: 'Know that'}),
      },
      'Hymns\t8\t008.mxl',
    );
    expect(issues.single.isError, isFalse);
    expect(issues.single.message, contains('verse 1'));
  });

  test('case, punctuation, hyphens and apostrophes are ignored when comparing',
      () {
    expect(
      _check(
        {
          '/n/008.mxl': _score({1: 'ALL PEO-PLE!', 2: 'Know, that'}),
        },
        'Hymns\t8\t008.mxl',
      ),
      isEmpty,
    );
  });

  test('a hymn the batch files lack, or listed twice, is an error', () {
    final issues = _check(
      {
        '/n/a.mxl': _score({1: 'All people', 2: 'Know that'}),
      },
      'Hymns\t9\ta.mxl\nHymns\t8\ta.mxl\nHymns\t8\ta.mxl',
    );
    expect(issues.map((i) => i.message), [
      contains('Hymns 9 is not in the batch files'),
      contains('Hymns 8 is listed twice'),
    ]);
  });

  test('a file that is not MusicXML is an error', () {
    final issues = _check({'/n/008.mxl': 'not xml'}, 'Hymns\t8\t008.mxl');
    expect(issues.single.message, contains('not XML'));
  });

  test('the bucket path is under the hymn id', () {
    expect(notationPath('abc'), 'abc/notation.mxl');
  });
}
