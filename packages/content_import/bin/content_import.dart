import 'dart:io';

import 'package:args/args.dart';
import 'package:content_import/content_import.dart';

const _usage = 'Usage: dart run content_import <batch files...> [options]';

/// Reads transcribed batch files and writes the SQL that loads them (ADR 0008).
///
/// Nothing is written when any file has errors, so a broken batch never half-imports.
void main(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'out',
      abbr: 'o',
      help: 'Where to write the SQL (default: standard output).',
    )
    ..addFlag(
      'publish-all',
      negatable: false,
      help:
          'Also publish content whose copyright is not confirmed (development only).',
    )
    ..addOption(
      'default-section',
      defaultsTo: 'Hymns',
      help:
          'Section for hymns before any SECTION line; the app opens it first.',
    )
    ..addOption(
      'language',
      defaultsTo: 'en',
      help: 'Language code of the content.',
    )
    ..addOption(
      'year',
      help: 'Year to judge copyright by (default: this year).',
    )
    ..addOption(
      'music',
      help: 'Music map (section, number or title, part, path, page) to load '
          'as sheet music.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  final ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n$_usage\n${parser.usage}');
    exitCode = 64;
    return;
  }
  if (options.flag('help')) {
    stdout.writeln('$_usage\n${parser.usage}');
    return;
  }
  if (options.rest.isEmpty) {
    stderr.writeln('$_usage\n${parser.usage}');
    exitCode = 64;
    return;
  }

  final sources = <Source>[];
  for (final path in options.rest) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('$path: no such file');
      exitCode = 66;
      return;
    }
    sources.add(Source(path, file.readAsStringSync()));
  }

  final defaultSection = options.option('default-section')!;
  final book = parseSources(sources, defaultSection: defaultSection);
  for (final issue in book.issues) {
    stderr.writeln(issue);
  }
  if (book.hasErrors) {
    final errors = book.issues.where((i) => i.isError).length;
    stderr.writeln('$errors error${errors == 1 ? '' : 's'}: nothing written.');
    exitCode = 1;
    return;
  }

  List<MusicPiece>? music;
  final musicPath = options.option('music');
  if (musicPath != null) {
    final file = File(musicPath);
    if (!file.existsSync()) {
      stderr.writeln('$musicPath: no such file');
      exitCode = 66;
      return;
    }
    final issues = <Issue>[];
    music = parseMusicMap(Source(musicPath, file.readAsStringSync()), issues);
    issues.addAll(checkMusicMap(book, music, file: musicPath));
    for (final issue in issues) {
      stderr.writeln(issue);
    }
    if (issues.isNotEmpty) {
      stderr.writeln(
        '${issues.length} music map error${issues.length == 1 ? '' : 's'}: '
        'nothing written.',
      );
      exitCode = 1;
      return;
    }
  }

  final year = options.option('year');
  final plan = planImport(
    book,
    currentYear: year == null ? DateTime.now().year : int.parse(year),
    publishAll: options.flag('publish-all'),
    defaultSection: defaultSection,
    language: options.option('language')!,
    music: music,
  );
  final out = options.option('out');
  final sql = renderSql(plan);
  if (out == null) {
    stdout.write(sql);
  } else {
    File(out).writeAsStringSync(sql);
  }
  _summarize(book, plan, out);
}

/// Tells the person running the import what it holds and what will stay hidden.
void _summarize(Book book, ImportPlan plan, String? out) {
  final perSection = [
    for (final s in book.sections)
      '${book.hymns.where((h) => h.section == s).length} in $s',
  ];
  stderr.writeln('${book.hymns.length} hymns (${perSection.join(', ')}), '
      '${book.readings.length} readings.');
  final pieces = plan.rowsOf('hymn_assets').length;
  if (pieces > 0) stderr.writeln('$pieces pieces of sheet music.');

  final unpublished = <String>[];
  final drafts = <String>[];
  final hymnRows = plan.rowsOf('hymns').toList();
  for (final (i, h) in book.hymns.indexed) {
    final name =
        '${h.section} ${h.number == null ? '' : '${h.number} '}"${h.title}"';
    if (h.draft) {
      drafts.add(name);
    } else if (hymnRows[i].values['published'] == false) {
      unpublished.add(name);
    }
  }
  final readingRows = plan.rowsOf('readings').toList();
  for (final (i, r) in book.readings.indexed) {
    final name =
        '${r.number == null ? r.kind.toUpperCase() : 'READING ${r.number}'} "${r.title}"';
    if (r.draft) {
      drafts.add(name);
    } else if (readingRows[i].values['published'] == false) {
      unpublished.add(name);
    }
  }
  if (unpublished.isNotEmpty) {
    stderr.writeln(
      'Unpublished until copyright is confirmed: ${unpublished.join('; ')}',
    );
  }
  if (drafts.isNotEmpty) {
    stderr.writeln('Drafts (never published): ${drafts.join('; ')}');
  }
  if (out != null) stderr.writeln('Wrote $out');
}
