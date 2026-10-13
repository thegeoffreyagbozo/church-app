import 'database.dart';

/// Rebuilds `search_index` from the content tables (see [createSearchIndexSql]).
///
/// Line breaks become spaces and reading markup (`**bold**`, `- ` bullets) is dropped,
/// so snippets read as plain text.
Future<void> rebuildSearchIndex(ContentDatabase db) {
  return db.transaction(() async {
    await db.customStatement('DELETE FROM search_index');
    await db.customStatement('''
INSERT INTO search_index (body, item_type, item_id, field, label)
SELECT title, 'hymn', id, 1, NULL FROM hymns
UNION ALL
SELECT first_line, 'hymn', id, 2, NULL FROM hymns WHERE first_line IS NOT NULL
UNION ALL
SELECT replace(lyrics, char(10), ' '), 'hymn', hymn_id, 3,
       section_type || ':' || coalesce(section_number, '')
  FROM hymn_sections WHERE lyrics <> ''
UNION ALL
SELECT trim(coalesce(author, '') || ' ' || coalesce(composer, '')), 'hymn', id, 4, NULL
  FROM hymns WHERE author IS NOT NULL OR composer IS NOT NULL
UNION ALL
SELECT title, 'reading', id, 1, NULL FROM readings
UNION ALL
SELECT scripture_ref, 'reading', id, 4, NULL FROM readings
  WHERE scripture_ref IS NOT NULL
UNION ALL
SELECT ltrim(replace(replace(replace(body, '**', ''), char(10) || '- ', ' '),
                     char(10), ' '), '- '),
       'reading', reading_id, 3, NULL
  FROM reading_parts WHERE body <> ''
''');
  });
}
