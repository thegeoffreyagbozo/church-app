import 'package:drift/drift.dart';
import 'package:shared/shared.dart';

import '../catalog.dart';
import '../database.dart';
import '../models.dart';
import '../text.dart';
import 'query.dart';
import 'results.dart';
import 'scripture.dart';

/// Searches the hymn book offline (spec section 4).
class SearchEngine {
  SearchEngine(this._db, this._catalog);

  /// The most word matches returned.
  static const limit = 50;

  final ContentDatabase _db;
  final ContentCatalog _catalog;
  Future<List<_Cited>>? _citations;

  Future<SearchResults> search(String raw) async {
    final sections = await _catalog.sections();
    return switch (interpretQuery(raw, sections)) {
      EmptyInput() => SearchResults.empty,
      NumberInput(:final number) => _number(number, sections),
      SectionNumberInput(:final section, :final number) => _inSection(
        section,
        number,
        sections,
      ),
      ReadingNumberInput(:final number) => _reading(number, sections),
      ScriptureInput(:final ref, :final text) => _scripture(ref, text),
      WordsInput(:final text) => SearchResults(hits: await _words(text)),
    };
  }

  /// "268": the default section's 268, then 268 in the other sections and readings.
  Future<SearchResults> _number(int number, List<Section> sections) async {
    final home = sections.where((s) => s.isDefault).firstOrNull;
    final top = home == null ? null : await _hymnNumbered(home, number);
    return SearchResults(
      hits: [
        ?top,
        ...await _elsewhere(number, sections, skip: home),
        ?await _readingNumbered(number),
      ],
      exactTop: top != null,
      missing: home != null && top == null ? _missing(home, number) : null,
    );
  }

  /// "S2": that section's 2; if it has none, 2 wherever else it exists.
  Future<SearchResults> _inSection(
    Section section,
    int number,
    List<Section> sections,
  ) async {
    final hit = await _hymnNumbered(section, number);
    if (hit != null) return SearchResults(hits: [hit], exactTop: true);
    final home = sections.where((s) => s.isDefault).firstOrNull;
    return SearchResults(
      hits: [
        if (home != null && home != section) ?await _hymnNumbered(home, number),
        ...await _elsewhere(number, sections, skip: section, alsoSkip: home),
        ?await _readingNumbered(number),
      ],
      missing: _missing(section, number),
    );
  }

  /// "R5": reading 5; if there is none, hymn 5 wherever it exists.
  Future<SearchResults> _reading(int number, List<Section> sections) async {
    final hit = await _readingNumbered(number);
    if (hit != null) return SearchResults(hits: [hit], exactTop: true);
    final home = sections.where((s) => s.isDefault).firstOrNull;
    final range = await _db
        .customSelect(
          'SELECT MIN(number) AS lo, MAX(number) AS hi FROM readings',
          readsFrom: {_db.readings},
        )
        .getSingle();
    return SearchResults(
      hits: [
        if (home != null) ?await _hymnNumbered(home, number),
        ...await _elsewhere(number, sections, skip: home),
      ],
      missing: MissingNumber(
        type: ItemType.reading,
        number: number,
        lowest: range.read<int?>('lo'),
        highest: range.read<int?>('hi'),
      ),
    );
  }

  Future<List<SearchHit>> _elsewhere(
    int number,
    List<Section> sections, {
    Section? skip,
    Section? alsoSkip,
  }) async => [
    for (final s in sections)
      if (s.isNumbered && s != skip && s != alsoSkip)
        ?await _hymnNumbered(s, number),
  ];

  MissingNumber _missing(Section section, int number) => MissingNumber(
    type: ItemType.hymn,
    number: number,
    sectionName: section.name,
    lowest: section.lowestNumber,
    highest: section.highestNumber,
  );

  Future<SearchHit?> _hymnNumbered(Section section, int number) async {
    final row = await _db
        .customSelect(
          'SELECT id, title, first_line FROM hymns '
          'WHERE hymnal_id = ? AND number = ?',
          variables: [Variable(section.id), Variable(number)],
          readsFrom: {_db.hymns},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return SearchHit(
      type: ItemType.hymn,
      id: row.read<String>('id'),
      number: number,
      title: row.read<String>('title'),
      section: section,
      match: MatchKind.number,
      preview: row.read<String?>('first_line'),
    );
  }

  Future<SearchHit?> _readingNumbered(int number) async {
    final row = await _db
        .customSelect(
          '$_readingSelect WHERE r.number = ?',
          variables: [Variable(number)],
          readsFrom: {_db.readings, _db.readingParts},
        )
        .getSingleOrNull();
    return row == null ? null : _readingHit(row, MatchKind.number);
  }

  static const _readingSelect =
      'SELECT r.id, r.kind, r.number, r.title, '
      '(SELECT p.body FROM reading_parts p WHERE p.reading_id = r.id '
      'ORDER BY p.position LIMIT 1) AS first_part FROM readings r';

  SearchHit _readingHit(QueryRow row, MatchKind match, {String? snippet}) =>
      SearchHit(
        type: ItemType.reading,
        id: row.read<String>('id'),
        number: row.read<int?>('number'),
        title: row.read<String>('title'),
        readingKind: ReadingKind.fromWire(row.read<String>('kind')),
        match: match,
        preview: previewLine(row.read<String?>('first_part')),
        snippet: snippet,
      );

  /// "Psalm 23": items citing that passage (readings, then hymns), then word matches.
  Future<SearchResults> _scripture(BibleRef ref, String text) async {
    final cited = [
      for (final c in await (_citations ??= _loadCitations()))
        if (c.spans.any((s) => s.covers(ref))) c,
    ];
    final sections = {for (final s in await _catalog.sections()) s.id: s};
    final hits = <SearchHit>[];
    final seen = <String>{};
    for (final c in cited) {
      if (!seen.add('${c.type.name}:${c.id}')) continue;
      final hit = c.type == ItemType.reading
          ? await _readingById(c.id, c.text)
          : await _hymnById(c.id, c.text, sections);
      if (hit != null) hits.add(hit);
    }
    hits.sort(_citedOrder);
    final words = await _words(text);
    return SearchResults(
      hits: [
        ...hits,
        for (final w in words)
          if (!seen.contains('${w.type.name}:${w.id}')) w,
      ],
    );
  }

  static int _citedOrder(SearchHit a, SearchHit b) {
    if (a.type != b.type) return a.type == ItemType.reading ? -1 : 1;
    final home = (a.section?.isDefault ?? false) ? 0 : 1;
    final otherHome = (b.section?.isDefault ?? false) ? 0 : 1;
    if (home != otherHome) return home - otherHome;
    return (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30);
  }

  Future<List<_Cited>> _loadCitations() async {
    final rows = await _db
        .customSelect(
          "SELECT 'hymn' AS t, id, scripture_ref AS ref FROM hymns "
          'WHERE scripture_ref IS NOT NULL '
          "UNION ALL SELECT 'reading', id, scripture_ref FROM readings "
          'WHERE scripture_ref IS NOT NULL '
          "UNION ALL SELECT 'reading', reading_id, scripture_ref FROM reading_parts "
          'WHERE scripture_ref IS NOT NULL',
          readsFrom: {_db.hymns, _db.readings, _db.readingParts},
        )
        .get();
    return [
      for (final r in rows)
        _Cited(
          ItemType.fromWire(r.read<String>('t')),
          r.read<String>('id'),
          r.read<String>('ref'),
          parseScriptureRefs(r.read<String>('ref')),
        ),
    ];
  }

  Future<SearchHit?> _readingById(String id, String reference) async {
    final row = await _db
        .customSelect(
          '$_readingSelect WHERE r.id = ?',
          variables: [Variable(id)],
          readsFrom: {_db.readings, _db.readingParts},
        )
        .getSingleOrNull();
    return row == null
        ? null
        : _readingHit(row, MatchKind.scripture, snippet: reference);
  }

  Future<SearchHit?> _hymnById(
    String id,
    String reference,
    Map<String, Section> sections,
  ) async {
    final row = await (_db.select(
      _db.hymns,
    )..where((h) => h.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return SearchHit(
      type: ItemType.hymn,
      id: row.id,
      number: row.number,
      title: row.title,
      section: sections[row.hymnalId],
      match: MatchKind.scripture,
      preview: row.firstLine,
      snippet: reference,
    );
  }

  /// Word search: each item once, at its best match (titles, then first lines, then
  /// verses and reading lines, then credits), ranked by relevance within each.
  Future<List<SearchHit>> _words(String text) async {
    final match = ftsMatchQuery(text);
    if (match == null) return const [];
    final rows = await _db
        .customSelect(
          '''
WITH m AS (
  SELECT rowid AS rid, item_type, item_id, field, label, rank,
         row_number() OVER (
           PARTITION BY item_type, item_id ORDER BY field, rank) AS rn
  FROM search_index WHERE search_index MATCH ?1
),
best AS (SELECT * FROM m WHERE rn = 1 ORDER BY field, rank LIMIT ?2)
SELECT best.item_type, best.item_id, best.field, best.label,
       snippet(search_index, 0, char(2), char(3), '…', 24) AS snip,
       h.number AS hymn_number, h.title AS hymn_title, h.first_line, h.hymnal_id,
       r.number AS reading_number, r.title AS reading_title, r.kind,
       (SELECT p.body FROM reading_parts p WHERE p.reading_id = r.id
        ORDER BY p.position LIMIT 1) AS first_part
FROM search_index
JOIN best ON search_index.rowid = best.rid
LEFT JOIN hymns h ON best.item_type = 'hymn' AND h.id = best.item_id
LEFT JOIN readings r ON best.item_type = 'reading' AND r.id = best.item_id
WHERE search_index MATCH ?1
ORDER BY best.field, best.rank, best.item_id
''',
          variables: [Variable(match), Variable(limit)],
          readsFrom: {_db.hymns, _db.readings, _db.readingParts},
        )
        .get();
    final sections = {for (final s in await _catalog.sections()) s.id: s};
    return [
      for (final r in rows)
        if (r.read<String>('item_type') == ItemType.hymn.wireValue)
          SearchHit(
            type: ItemType.hymn,
            id: r.read<String>('item_id'),
            number: r.read<int?>('hymn_number'),
            title: r.read<String>('hymn_title'),
            section: sections[r.read<String>('hymnal_id')],
            match: _fields[r.read<int>('field')]!,
            preview: r.read<String?>('first_line'),
            snippet: r.read<String>('snip'),
            sectionType: _sectionType(r.read<String?>('label')),
            sectionNumber: _sectionNumber(r.read<String?>('label')),
          )
        else
          SearchHit(
            type: ItemType.reading,
            id: r.read<String>('item_id'),
            number: r.read<int?>('reading_number'),
            title: r.read<String>('reading_title'),
            readingKind: ReadingKind.fromWire(r.read<String>('kind')),
            match: _fields[r.read<int>('field')]!,
            preview: previewLine(r.read<String?>('first_part')),
            snippet: r.read<String>('snip'),
          ),
    ];
  }

  static const _fields = {
    1: MatchKind.title,
    2: MatchKind.firstLine,
    3: MatchKind.text,
    4: MatchKind.credits,
  };

  static HymnSectionType? _sectionType(String? label) =>
      label == null ? null : HymnSectionType.fromWire(label.split(':').first);

  static int? _sectionNumber(String? label) =>
      label == null ? null : int.tryParse(label.split(':').last);
}

/// An item whose scripture reference (or one of whose parts') was parsed.
class _Cited {
  const _Cited(this.type, this.id, this.text, this.spans);
  final ItemType type;
  final String id;
  final String text;
  final List<ScriptureSpan> spans;
}
