import 'dart:io';

import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('content_db_build'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('writes a database with its bundle info and search index', () async {
    final out = '${dir.path}/assets/content.db';

    final summary = await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12, 9),
      source: 'example.supabase.co',
    );

    expect(summary.hymns, 8);
    final db = ContentDatabase(NativeDatabase(File(out)));
    addTearDown(db.close);
    final info = await db.select(db.bundleInfo).getSingle();
    expect(info.builtAt, DateTime.utc(2026, 10, 12, 9));
    expect(info.source, 'example.supabase.co');
    final hits = await db
        .customSelect(
          'SELECT item_id FROM search_index WHERE search_index MATCH ?',
          variables: [Variable('"cleft"*')],
        )
        .get();
    expect(hits.map((r) => r.read<String>('item_id')), contains('hymn-1'));
  });

  test('writes content.json beside the database', () async {
    final out = '${dir.path}/content.db';

    await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12, 9),
      source: 'test',
    );

    final version = BundleVersion.parse(
      File(versionFileFor(out)).readAsStringSync(),
    );
    expect(version.builtAt, DateTime.utc(2026, 10, 12, 9));
    expect(version.schemaVersion, ContentDatabase.version);
  });

  test('replaces an earlier build', () async {
    final out = '${dir.path}/content.db';
    File(out).writeAsStringSync('not a database');

    await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12),
      source: 'test',
    );

    final db = ContentDatabase(NativeDatabase(File(out)));
    addTearDown(db.close);
    expect(await db.select(db.readings).get(), hasLength(5));
  });
}
