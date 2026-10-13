import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// The on-phone hymn book: content mirrored from Supabase, its search index, and the
/// phone-only tables (ADR 0001). `bin/build_content_db.dart` builds it; the app opens
/// a copy of the bundled file.
@DriftDatabase(
  tables: [
    Hymnals,
    HymnCategories,
    Hymns,
    HymnSections,
    Readings,
    ReadingParts,
    Church,
    BundleInfo,
    Settings,
    RecentlyOpened,
  ],
)
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.executor);

  /// Stamped into every built file. Bump it with a migration when a table changes.
  static const version = 1;

  @override
  int get schemaVersion => version;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(createSearchIndexSql);
    },
  );
}

/// One row per searchable text. `field` ranks matches (1 titles, 2 first lines,
/// 3 verses and reading lines, 4 credits and references); `label` names a hymn section
/// as `type:number` (e.g. `verse:4`, `chorus:`).
const createSearchIndexSql = '''
CREATE VIRTUAL TABLE search_index USING fts5(
  body,
  item_type UNINDEXED,
  item_id UNINDEXED,
  field UNINDEXED,
  label UNINDEXED,
  tokenize = 'unicode61 remove_diacritics 2',
  prefix = '2 3'
)''';
