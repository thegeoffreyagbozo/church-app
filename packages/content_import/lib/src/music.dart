import 'model.dart';

/// One cut-out piece of a hymn's printed music, from the music map (`music.tsv`).
class MusicPiece {
  const MusicPiece(
    this.section,
    this.key,
    this.part,
    this.path,
    this.page,
    this.line,
  );

  final String section;

  /// The hymn's number, or its title when it has none (as in the batch files).
  final String key;

  /// 1 for the first piece of a hymn.
  final int part;

  /// Where the image is in the `sheet-music` bucket, such as `hymns/002-1.png`.
  final String path;

  /// The page of the music book it was cut from.
  final int? page;
  final int line;

  /// The hymn's natural key, as the importer builds ids from it.
  String get hymnKey => '$section/${int.tryParse(key) ?? key.toLowerCase()}';
}

/// Reads a music map: `section<TAB>number or title<TAB>part<TAB>path<TAB>page` per
/// row; `#` lines and blank lines are skipped. Problems are added to [issues].
List<MusicPiece> parseMusicMap(Source source, List<Issue> issues) {
  final pieces = <MusicPiece>[];
  final lines = source.text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final f = line.split('\t');
    final part = f.length == 5 ? int.tryParse(f[2]) : null;
    if (part == null || part < 1 || f[3].isEmpty) {
      issues.add(
        Issue(
          source.name,
          i + 1,
          'expected section, number or title, part, path and page '
          'separated by tabs',
        ),
      );
      continue;
    }
    pieces.add(MusicPiece(f[0], f[1], part, f[3], int.tryParse(f[4]), i + 1));
  }
  return pieces;
}

/// Pieces whose hymn isn't in [book], repeated parts, and parts that don't start at 1
/// or skip one.
List<Issue> checkMusicMap(
  Book book,
  List<MusicPiece> music, {
  String file = 'music map',
}) {
  final hymns = {
    for (final h in book.hymns)
      '${h.section}/${h.number ?? h.title!.toLowerCase()}',
  };
  final issues = <Issue>[];
  final parts = <String, Set<int>>{};
  final firstLine = <String, int>{};
  for (final m in music) {
    final name = '${m.section} ${m.key}';
    if (!hymns.contains(m.hymnKey)) {
      issues.add(Issue(file, m.line, '$name is not in the batch files'));
      continue;
    }
    firstLine.putIfAbsent(m.hymnKey, () => m.line);
    if (!(parts[m.hymnKey] ??= {}).add(m.part)) {
      issues.add(Issue(file, m.line, '$name has part ${m.part} twice'));
    }
  }
  for (final MapEntry(key: hymn, value: seen) in parts.entries) {
    final last = seen.reduce((a, b) => a > b ? a : b);
    for (var p = 1; p < last; p++) {
      if (!seen.contains(p)) {
        final next = seen.where((s) => s > p).reduce((a, b) => a < b ? a : b);
        issues.add(
          Issue(
            file,
            firstLine[hymn]!,
            '${hymn.replaceFirst('/', ' ')} has part $next but no part $p',
          ),
        );
      }
    }
  }
  return issues;
}
