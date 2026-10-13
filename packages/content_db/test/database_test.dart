import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late ContentDatabase db;

  setUp(() => db = ContentDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('creates the content, phone-only and search tables', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();

    expect(
      names,
      containsAll([
        'hymnals',
        'hymn_categories',
        'hymns',
        'hymn_sections',
        'readings',
        'reading_parts',
        'church',
        'bundle_info',
        'settings',
        'recently_opened',
        'search_index',
      ]),
    );
  });

  test('stamps the schema version', () async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();

    expect(row.read<int>('user_version'), ContentDatabase.version);
  });

  test('the search index folds accents and matches word beginnings', () async {
    await db.customInsert(
      'INSERT INTO search_index (body, item_type, item_id, field) '
      'VALUES (?, ?, ?, ?)',
      variables: [
        Variable('Crème brûlée'),
        Variable('hymn'),
        Variable('h1'),
        Variable(3),
      ],
    );

    final rows = await db
        .customSelect(
          'SELECT item_id FROM search_index WHERE search_index MATCH ?',
          variables: [Variable('"creme"* "bru"*')],
        )
        .get();

    expect(rows.single.read<String>('item_id'), 'h1');
  });
}
