import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('content_db_cli'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ProcessResult> run(List<String> args) => Process.run(
    Platform.resolvedExecutable,
    ['run', 'bin/build_content_db.dart', ...args],
  );

  test('builds from a saved snapshot and says what it wrote', () async {
    final out = '${dir.path}/content.db';

    final result = await run([
      '--from-json',
      'test/fixtures/sample_content.json',
      '--out',
      out,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      result.stdout,
      contains(
        '3 sections, 8 hymns (15 verses and choruses), 5 readings (12 parts)',
      ),
    );
    expect(File(out).existsSync(), isTrue);
    expect(File('${dir.path}/content.json').existsSync(), isTrue);
  });

  test('explains its usage when --out is missing', () async {
    final result = await run([
      '--from-json',
      'test/fixtures/sample_content.json',
    ]);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('--out'));
  });

  test('stops when the snapshot file is missing', () async {
    final result = await run([
      '--from-json',
      '${dir.path}/nope.json',
      '--out',
      '${dir.path}/x.db',
    ]);

    expect(result.exitCode, 66);
  });
}
