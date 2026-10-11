import 'dart:io';

import 'package:test/test.dart';

/// Runs the real command-line tool, the way a person would.
Future<ProcessResult> importer(List<String> args) => Process.run(
      Platform.resolvedExecutable,
      ['run', 'bin/content_import.dart', ...args],
    );

void main() {
  late Directory dir;
  setUp(
    () async =>
        dir = await Directory.systemTemp.createTemp('content_import_test'),
  );
  tearDown(() async => dir.delete(recursive: true));

  test(
      'writes the SQL and lists what stays unpublished until copyright is confirmed',
      () async {
    final input = File('${dir.path}/batch.txt')..writeAsStringSync('''
SECTION Hymns
HYMN 267
Title: All Things Work Out for Good
Music: John W. Peterson, 1921-

1
All things work out for good, we know.

HYMN 268
Title: How Firm a Foundation
Music: From Caldwell's Union Harmony, 1837

1
How firm a foundation, ye saints of the Lord.
''');
    final out = File('${dir.path}/import.sql');
    final result =
        await importer([input.path, '--out', out.path, '--year', '2026']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(out.readAsStringSync(), contains('insert into public.hymns'));
    expect(
      result.stderr,
      contains(
        'Unpublished until copyright is confirmed: Hymns 267 "All Things Work Out for Good"',
      ),
    );
    expect(result.stderr, isNot(contains('268')));
  });

  test('writes nothing when the input has errors, and says where they are',
      () async {
    final input = File('${dir.path}/bad.txt')
      ..writeAsStringSync('HYMN 5\n\n1\nx\n');
    final out = File('${dir.path}/import.sql');
    final result = await importer([input.path, '--out', out.path]);
    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains('${input.path}:1: error: HYMN 5 has no Title'),
    );
    expect(out.existsSync(), isFalse);
  });

  test('explains its usage when no files are given', () async {
    final result = await importer([]);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('Usage:'));
  });
}
