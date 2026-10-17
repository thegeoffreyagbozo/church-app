import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

void main() {
  test('each row is upserted by id, and a soft-deleted row comes back', () {
    final sql = renderSql(
      ImportPlan(
        [
          const Row('hymnals', {
            'id': 'a1',
            'name': "Pastor's Hymns",
            'sort_order': 0,
            'is_default': true,
            'description': null,
          }),
        ],
        [],
      ),
    );
    expect(
      sql,
      contains(
        'insert into public.hymnals (id, name, sort_order, is_default, description)',
      ),
    );
    expect(sql, contains("values ('a1', 'Pastor''s Hymns', 0, true, null)"));
    expect(
      sql,
      contains('on conflict (id) do update set name = excluded.name, '
          'sort_order = excluded.sort_order, is_default = excluded.is_default, '
          'description = excluded.description, deleted_at = null;'),
    );
  });

  test('multi-line text stays one literal', () {
    final sql = renderSql(
      ImportPlan(
        [
          const Row(
            'hymn_sections',
            {'id': 's1', 'lyrics': 'line one\nline two'},
          ),
        ],
        [],
      ),
    );
    expect(sql, contains("values ('s1', 'line one\nline two')"));
  });

  test('children a batch no longer has are soft-deleted after the upserts', () {
    final sql = renderSql(
      ImportPlan(
        [
          const Row('hymns', {'id': 'h1'}),
        ],
        [const Cleanup('hymn_sections', 'hymn_id', 'h1', 3)],
      ),
    );
    const cleanup = 'update public.hymn_sections set deleted_at = now()\n'
        "where hymn_id = 'h1' and position >= 3 and deleted_at is null;";
    expect(sql, contains(cleanup));
    expect(
      sql.indexOf(cleanup),
      greaterThan(sql.indexOf('insert into public.hymns')),
    );
  });

  test('a cleanup can order children by another column', () {
    final sql = renderSql(
      ImportPlan(const [], [
        const Cleanup(
          'hymn_assets',
          'hymn_id',
          'h1',
          2,
          orderColumn: 'sort_order',
        ),
      ]),
    );
    expect(
      sql,
      contains(
        "where hymn_id = 'h1' and sort_order >= 2 and deleted_at is null;",
      ),
    );
  });

  test('a cleanup can be limited to one kind of child', () {
    final sql = renderSql(
      ImportPlan(const [], [
        const Cleanup(
          'hymn_assets',
          'hymn_id',
          'h1',
          1,
          orderColumn: 'sort_order',
          kind: 'sheet_music_image',
        ),
      ]),
    );
    expect(
      sql,
      contains(
        "where hymn_id = 'h1' and sort_order >= 1 "
        "and kind = 'sheet_music_image' and deleted_at is null;",
      ),
    );
  });

  test('everything runs in one transaction', () {
    final sql = renderSql(
      ImportPlan(
        [
          const Row('hymns', {'id': 'h1'}),
        ],
        [],
      ),
    );
    expect(sql.trim(), startsWith('begin;'));
    expect(sql.trim(), endsWith('commit;'));
  });
}
