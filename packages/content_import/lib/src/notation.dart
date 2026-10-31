import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared/shared.dart';

import 'model.dart';

/// One hymn's notation file, from the notation map (`notation.tsv`).
class NotationEntry {
  const NotationEntry(this.section, this.key, this.file, this.line);

  final String section;

  /// The hymn's number, or its title when it has none (as in the batch files).
  final String key;

  /// The `.mxl` file on this computer.
  final String file;
  final int line;

  /// The hymn's natural key, as the importer builds ids from it.
  String get hymnKey => '$section/${int.tryParse(key) ?? key.toLowerCase()}';
}

/// Where a hymn's notation lives in the `sheet-music` bucket.
String notationPath(String hymnId) => '$hymnId/notation.mxl';

/// Reads a notation map: `section<TAB>number or title<TAB>file` per row, the file
/// relative to [baseDir]; `#` lines and blank lines are skipped.
List<NotationEntry> parseNotationMap(
  Source source,
  String baseDir,
  List<Issue> issues,
) {
  final entries = <NotationEntry>[];
  final lines = source.text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final f = line.split('\t');
    if (f.length != 3 || f.any((field) => field.trim().isEmpty)) {
      issues.add(
        Issue(
          source.name,
          i + 1,
          'expected section, number or title, and file separated by tabs',
        ),
      );
      continue;
    }
    entries.add(NotationEntry(f[0], f[1], p.join(baseDir, f[2]), i + 1));
  }
  return entries;
}

/// [words] for comparing: lower case, letters, digits and single spaces only.
String _plain(String words) => words
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Problems with the files [entries] name: hymns the batch files lack or listed
/// twice, files that aren't MusicXML, and files that break the drawn-notation layout
/// (two staves, two voices on each, verses numbered from 1 without gaps). Words that
/// differ from the batch text are warnings: the file may be right and the batch wrong.
List<Issue> checkNotation(
  Book book,
  List<NotationEntry> entries, {
  String file = 'notation map',
  List<int> Function(String path)? read,
}) {
  final readFile = read ?? (path) => File(path).readAsBytesSync();
  final hymns = {
    for (final h in book.hymns)
      '${h.section}/${h.number ?? h.title!.toLowerCase()}': h,
  };
  final issues = <Issue>[];
  final seen = <String>{};
  for (final e in entries) {
    final name = '${e.section} ${e.key}';
    final hymn = hymns[e.hymnKey];
    if (hymn == null) {
      issues.add(Issue(file, e.line, '$name is not in the batch files'));
      continue;
    }
    if (!seen.add(e.hymnKey)) {
      issues.add(Issue(file, e.line, '$name is listed twice'));
      continue;
    }
    final NotationFacts facts;
    try {
      facts = readNotationFacts(musicXmlFromFile(readFile(e.file)));
    } on NotationFileException catch (x) {
      issues.add(Issue(file, e.line, '$name: ${x.message}'));
      continue;
    } on FileSystemException catch (x) {
      issues.add(Issue(file, e.line, '$name: ${x.message} (${e.file})'));
      continue;
    }
    if (facts.staves != 2) {
      issues.add(
        Issue(file, e.line, '$name has ${facts.staves} staves, not 2 staves'),
      );
      continue;
    }
    for (final staff in [1, 2]) {
      final count = facts.voices[staff]?.length ?? 0;
      if (count < 2) {
        issues.add(
          Issue(
            file,
            e.line,
            '$name: staff $staff has $count voice${count == 1 ? '' : 's'}, '
            'not 2',
          ),
        );
      }
    }
    final expected = [for (var v = 1; v <= facts.verses.length; v++) v];
    if (facts.verses.isEmpty || facts.verses.join(',') != expected.join(',')) {
      issues.add(
        Issue(
          file,
          e.line,
          '$name has verses ${facts.verses.join(', ')}; '
          'number them from 1 without gaps',
        ),
      );
      continue;
    }
    final verses = [
      for (final s in hymn.sections)
        if (s.type == 'verse') s.lyrics,
    ];
    final chorus = [
      for (final s in hymn.sections)
        if (s.type != 'verse') s.lyrics,
    ].join(' ');
    for (final v in facts.verses) {
      final verse = v <= verses.length ? verses[v - 1] : '';
      final drawn = _plain(facts.words[v]!);
      if (drawn != _plain(verse) && drawn != _plain('$verse $chorus')) {
        issues.add(
          Issue(
            file,
            e.line,
            "$name: verse $v's words differ from the batch text",
            isError: false,
          ),
        );
      }
    }
  }
  return issues;
}
