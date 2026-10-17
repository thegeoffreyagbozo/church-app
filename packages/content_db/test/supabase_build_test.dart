@Tags(['supabase'])
library;

import 'dart:io';

import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// Builds from a running Supabase stack loaded with the importer's sample book (see the
/// backend job in .github/workflows/ci.yml). Skipped unless SUPABASE_URL and
/// SUPABASE_KEY are set.
void main() {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_KEY'];

  test(
    'builds only the published content',
    () async {
      final dir = Directory.systemTemp.createTempSync('content_db_supabase');
      addTearDown(() => dir.deleteSync(recursive: true));
      final source = SupabaseContentSource(url: url!, key: key!);
      addTearDown(source.close);
      final out = '${dir.path}/content.db';
      final snapshot = await source.fetch();
      // CI imports the sample with its music map; only published hymns' music comes back.
      expect(
        bundledMusic(snapshot).map((r) => r['storage_path']),
        contains('hymns/001-1.png'),
      );
      expect(
        bundledMusic(snapshot).map((r) => r['storage_path']),
        isNot(contains('hymns/002-1.png')),
      );

      await buildContentDatabase(
        snapshot,
        outPath: out,
        builtAt: DateTime.now().toUtc(),
        source: 'ci',
      );

      final db = ContentDatabase(NativeDatabase(File(out)));
      addTearDown(db.close);
      final titles = (await db.select(db.hymns).get()).map((h) => h.title);
      expect(titles, contains('Rock of Ages'));
      expect(titles, isNot(contains('A Protected Hymn')));
      final readings = (await db.select(db.readings).get()).map((r) => r.title);
      expect(readings, isNot(contains('Unfinished Reading')));
      final hits = await db
          .customSelect(
            'SELECT item_id FROM search_index WHERE search_index MATCH ?',
            variables: [Variable('"cleft"*')],
          )
          .get();
      expect(hits, isNotEmpty);
    },
    skip: url == null || key == null
        ? 'needs SUPABASE_URL and SUPABASE_KEY'
        : null,
  );
}
