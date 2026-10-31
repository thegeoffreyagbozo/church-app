import 'package:drift/drift.dart';
import 'package:shared/shared.dart';

import 'database.dart';
import 'models.dart';
import 'text.dart';

/// Read queries over the hymn book. Content doesn't change while the database is open,
/// so the section list is loaded once.
class ContentCatalog {
  ContentCatalog(this._db);

  final ContentDatabase _db;
  Future<List<Section>>? _sections;

  /// Sections that hold hymns, in book order, with the default one marked.
  Future<List<Section>> sections() => _sections ??= _loadSections();

  Future<List<Section>> _loadSections() async {
    final rows = await _db
        .customSelect(
          'SELECT y.id, y.name, y.is_default, COUNT(h.id) AS n, '
          'MIN(h.number) AS lo, MAX(h.number) AS hi '
          'FROM hymnals y JOIN hymns h ON h.hymnal_id = y.id '
          'GROUP BY y.id ORDER BY y.sort_order, y.name',
          readsFrom: {_db.hymnals, _db.hymns},
        )
        .get();
    bool numbered(QueryRow r) => r.read<int?>('hi') != null;
    final marked = rows.where((r) => r.read<bool>('is_default') && numbered(r));
    final fallback = rows.where(numbered);
    final defaultId = (marked.isNotEmpty ? marked : fallback)
        .map((r) => r.read<String>('id'))
        .firstOrNull;
    return [
      for (final r in rows)
        Section(
          id: r.read<String>('id'),
          name: r.read<String>('name'),
          isDefault: r.read<String>('id') == defaultId,
          count: r.read<int>('n'),
          lowestNumber: r.read<int?>('lo'),
          highestNumber: r.read<int?>('hi'),
        ),
    ];
  }

  /// The section a bare number refers to, if the book has numbered hymns.
  Future<Section?> defaultSection() async =>
      (await sections()).where((s) => s.isDefault).firstOrNull;

  Future<Section?> section(String id) async =>
      (await sections()).where((s) => s.id == id).firstOrNull;

  /// The hymns of a section: by number, or in book order when unnumbered. A hymn's
  /// category is its contents [HymnListItem.group] when it belongs to this section,
  /// else its [HymnListItem.topic].
  Future<List<HymnListItem>> hymnsIn(String sectionId) async {
    final rows = await _db
        .customSelect(
          'SELECT h.id, h.number, h.title, h.first_line, c.id AS category_id, '
          'c.name AS category, c.part, c.section_id '
          'FROM hymns h LEFT JOIN hymn_categories c ON c.id = h.category_id '
          'WHERE h.hymnal_id = ? '
          'ORDER BY h.number IS NULL, h.number, h.sort_order, h.title',
          variables: [Variable(sectionId)],
          readsFrom: {_db.hymns, _db.hymnCategories},
        )
        .get();
    return [
      for (final r in rows)
        _listItem(r, grouped: r.read<String?>('section_id') == sectionId),
    ];
  }

  HymnListItem _listItem(QueryRow r, {required bool grouped}) {
    final category = r.read<String?>('category');
    return HymnListItem(
      id: r.read<String>('id'),
      number: r.read<int?>('number'),
      title: r.read<String>('title'),
      firstLine: r.read<String?>('first_line'),
      topic: grouped ? null : category,
      group: grouped && category != null
          ? HymnGroup(
              id: r.read<String>('category_id'),
              name: category,
              part: r.read<String?>('part'),
            )
          : null,
    );
  }

  /// The id of hymn [number] in [sectionId], if the app has it.
  Future<String?> hymnIdByNumber(String sectionId, int number) async {
    final row =
        await (_db.select(_db.hymns)
              ..where((h) => h.hymnalId.equals(sectionId))
              ..where((h) => h.number.equals(number)))
            .getSingleOrNull();
    return row?.id;
  }

  /// [hymnId]'s notation file (compressed MusicXML), or null when it has none.
  Future<Uint8List?> notation(String hymnId) async => (await (_db.select(
    _db.hymnNotation,
  )..where((n) => n.hymnId.equals(hymnId))).getSingleOrNull())?.mxl;

  Future<HymnDetail?> hymn(String id) async {
    final row = await (_db.select(
      _db.hymns,
    )..where((h) => h.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final section = await this.section(row.hymnalId);
    if (section == null) return null;
    final texts =
        await (_db.select(_db.hymnSections)
              ..where((s) => s.hymnId.equals(id))
              ..orderBy([(s) => OrderingTerm(expression: s.position)]))
            .get();
    final category = row.categoryId == null
        ? null
        : await (_db.select(
            _db.hymnCategories,
          )..where((c) => c.id.equals(row.categoryId!))).getSingleOrNull();
    final grouped = category != null && category.sectionId == row.hymnalId;
    final music =
        await (_db.select(_db.hymnMusic)
              ..where((m) => m.hymnId.equals(id))
              ..orderBy([(m) => OrderingTerm(expression: m.position)]))
            .get();
    final notation = await (_db.select(
      _db.hymnNotation,
    )..where((n) => n.hymnId.equals(id))).getSingleOrNull();
    final home = await defaultSection();
    return HymnDetail(
      id: row.id,
      section: section,
      number: row.number,
      title: row.title,
      author: row.author,
      composer: row.composer,
      tuneName: row.tuneName,
      meter: row.meter,
      musicKey: row.musicKey,
      topic: grouped ? null : category?.name,
      group: grouped
          ? HymnGroup(id: category.id, name: category.name, part: category.part)
          : null,
      music: [
        for (final m in music)
          HymnMusicPart(id: m.id, width: m.width, height: m.height),
      ],
      notationVerses: notation?.verses ?? 0,
      isPublicDomain: row.isPublicDomain,
      texts: [
        for (final t in texts)
          HymnText(
            type: HymnSectionType.fromWire(t.sectionType),
            number: t.sectionNumber,
            lyrics: t.lyrics,
          ),
      ],
      alsoSungTo: [
        for (final tune in parseAlsoSungTo(row.choristerNotes))
          AlsoSungTo(
            tune: tune.tune,
            number: tune.number,
            hymnId: tune.number == null || home == null
                ? null
                : await hymnIdByNumber(home.id, tune.number!),
          ),
      ],
    );
  }

  /// Every reading: numbered ones by number, then the unnumbered (creeds, covenants).
  Future<List<ReadingListItem>> readings() async {
    final rows = await _db
        .customSelect(
          'SELECT r.id, r.kind, r.number, r.title, r.scripture_ref, '
          '(SELECT p.body FROM reading_parts p WHERE p.reading_id = r.id '
          'ORDER BY p.position LIMIT 1) AS first_part '
          'FROM readings r '
          'ORDER BY r.number IS NULL, r.number, r.sort_order, r.title',
          readsFrom: {_db.readings, _db.readingParts},
        )
        .get();
    return [
      for (final r in rows)
        ReadingListItem(
          id: r.read<String>('id'),
          kind: ReadingKind.fromWire(r.read<String>('kind')),
          number: r.read<int?>('number'),
          title: r.read<String>('title'),
          scriptureRef: r.read<String?>('scripture_ref'),
          preview: previewLine(r.read<String?>('first_part')),
        ),
    ];
  }

  Future<ReadingDetail?> reading(String id) async {
    final row = await (_db.select(
      _db.readings,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final parts =
        await (_db.select(_db.readingParts)
              ..where((p) => p.readingId.equals(id))
              ..orderBy([(p) => OrderingTerm(expression: p.position)]))
            .get();
    return ReadingDetail(
      id: row.id,
      kind: ReadingKind.fromWire(row.kind),
      number: row.number,
      title: row.title,
      scriptureRef: row.scriptureRef,
      isPublicDomain: row.isPublicDomain,
      parts: [
        for (final p in parts)
          ReadingPartText(
            body: p.body,
            number: p.number,
            speaker: ReadingSpeaker.fromWire(p.speaker),
            scriptureRef: p.scriptureRef,
          ),
      ],
    );
  }

  Future<ChurchProfile?> church() async {
    final row = await (_db.select(_db.church)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    return ChurchProfile(
      name: row.name,
      email: row.email,
      phone: row.phone,
      whatsapp: row.whatsapp,
      website: row.website,
      tagline: row.tagline,
    );
  }

  /// When the build tool made this copy of the hymn book.
  Future<DateTime?> builtAt() async {
    final row = await (_db.select(
      _db.bundleInfo,
    )..where((b) => b.id.equals(1))).getSingleOrNull();
    return row?.builtAt;
  }

  /// The last opened hymns and readings, newest first, skipping any no longer in the book.
  Future<List<RecentItem>> recentlyOpened() async {
    final rows = await _db
        .customSelect(
          'SELECT r.item_type, r.item_id, '
          'h.number AS hymn_number, h.title AS hymn_title, h.first_line, '
          'h.hymnal_id, d.number AS reading_number, d.title AS reading_title, '
          'd.kind, (SELECT p.body FROM reading_parts p '
          'WHERE p.reading_id = d.id ORDER BY p.position LIMIT 1) AS first_part '
          'FROM recently_opened r '
          "LEFT JOIN hymns h ON r.item_type = 'hymn' AND h.id = r.item_id "
          "LEFT JOIN readings d ON r.item_type = 'reading' AND d.id = r.item_id "
          'WHERE h.id IS NOT NULL OR d.id IS NOT NULL '
          'ORDER BY r.opened_at DESC',
          readsFrom: {_db.recentlyOpened, _db.hymns, _db.readings},
        )
        .get();
    final sections = {for (final s in await this.sections()) s.id: s};
    return [
      for (final r in rows)
        if (ItemType.fromWire(r.read<String>('item_type')) == ItemType.hymn)
          RecentItem(
            type: ItemType.hymn,
            id: r.read<String>('item_id'),
            number: r.read<int?>('hymn_number'),
            title: r.read<String>('hymn_title'),
            preview: r.read<String?>('first_line'),
            section: sections[r.read<String>('hymnal_id')],
          )
        else
          RecentItem(
            type: ItemType.reading,
            id: r.read<String>('item_id'),
            number: r.read<int?>('reading_number'),
            title: r.read<String>('reading_title'),
            preview: previewLine(r.read<String?>('first_part')),
            readingKind: ReadingKind.fromWire(r.read<String>('kind')),
          ),
    ];
  }
}
