import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> rowsFor(String itemId) async {
    final rows = await db
        .customSelect(
          'SELECT body, field, label FROM search_index WHERE item_id = ? '
          'ORDER BY field, label',
          variables: [Variable(itemId)],
        )
        .get();
    return [for (final r in rows) r.data];
  }

  test(
    'indexes a hymn by title, first line, each verse and its credits',
    () async {
      final rows = await rowsFor('hymn-1');

      expect(rows.map((r) => r['field']), [1, 2, 3, 3, 4]);
      expect(rows.first['body'], 'Rock of Ages');
      expect(rows[2]['label'], 'verse:1');
      expect(
        rows[2]['body'],
        startsWith('Rock of Ages, cleft for me, Let me hide'),
      );
      expect(rows.last['body'], contains('Toplady'));
    },
  );

  test('labels a chorus without a number', () async {
    final rows = await rowsFor('supp-1');

    expect(rows.map((r) => r['label']), contains('chorus:'));
  });

  test('indexes reading lines as plain text', () async {
    final rows = await rowsFor('reading-covenant');
    final lines = rows.where((r) => r['field'] == 3).map((r) => r['body']);

    expect(
      lines,
      contains(
        'We engage, therefore: to walk together in Christian '
        'love; to strive for the advancement of this church.',
      ),
    );
  });

  test('indexes a reading title and its scripture reference', () async {
    final rows = await rowsFor('reading-1');

    expect(rows.first, {
      'body': 'The Lord Is My Shepherd',
      'field': 1,
      'label': null,
    });
    expect(rows.last, {'body': 'Psalm 23', 'field': 4, 'label': null});
  });

  test('rebuilding replaces the previous index', () async {
    await rebuildSearchIndex(db);

    expect(await rowsFor('hymn-1'), hasLength(5));
  });
}
