import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// One row as the Supabase API returns it: column name to JSON value.
typedef ApiRow = Map<String, Object?>;

/// The columns read from each Supabase table, in the API's `select` syntax.
const snapshotColumns = {
  'hymnals': 'id,name,is_default,sort_order',
  'hymn_categories': 'id,name,sort_order',
  'hymns':
      'id,hymnal_id,category_id,number,title,first_line,author,composer,'
      'tune_name,meter,music_key,scripture_ref,chorister_notes,'
      'is_public_domain,sort_order',
  'hymn_sections': 'id,hymn_id,section_type,section_number,position,lyrics',
  'readings': 'id,kind,number,title,scripture_ref,is_public_domain,sort_order',
  'reading_parts': 'id,reading_id,position,number,speaker,body,scripture_ref',
  'church': 'id,name,email,phone,website,socials,tagline',
};

/// A church's published content, table by table, as the Supabase API returns it.
class ContentSnapshot {
  const ContentSnapshot({
    required this.hymnals,
    required this.categories,
    required this.hymns,
    required this.sections,
    required this.readings,
    required this.parts,
    required this.church,
  });

  /// Reads the JSON written by [toJson] (or a hand-made fixture of the same shape).
  factory ContentSnapshot.fromJson(Map<String, Object?> json) {
    List<ApiRow> rows(String table) => [
      for (final row in (json[table] as List<Object?>? ?? const []))
        (row! as Map<Object?, Object?>).cast<String, Object?>(),
    ];
    return ContentSnapshot(
      hymnals: rows('hymnals'),
      categories: rows('hymn_categories'),
      hymns: rows('hymns'),
      sections: rows('hymn_sections'),
      readings: rows('readings'),
      parts: rows('reading_parts'),
      church: rows('church'),
    );
  }

  factory ContentSnapshot.parse(String source) =>
      ContentSnapshot.fromJson(jsonDecode(source) as Map<String, Object?>);

  final List<ApiRow> hymnals;
  final List<ApiRow> categories;
  final List<ApiRow> hymns;
  final List<ApiRow> sections;
  final List<ApiRow> readings;
  final List<ApiRow> parts;
  final List<ApiRow> church;

  Map<String, Object?> toJson() => {
    'hymnals': hymnals,
    'hymn_categories': categories,
    'hymns': hymns,
    'hymn_sections': sections,
    'readings': readings,
    'reading_parts': parts,
    'church': church,
  };
}

/// What [importSnapshot] wrote, and how many rows it left out because their section,
/// hymn or reading isn't published.
class ImportSummary {
  const ImportSummary({
    required this.sections,
    required this.hymns,
    required this.verses,
    required this.readings,
    required this.parts,
    required this.skipped,
  });

  final int sections;
  final int hymns;
  final int verses;
  final int readings;
  final int parts;
  final int skipped;
}

/// Replaces the content tables of [db] with [snapshot]. Phone-only tables are untouched.
///
/// The API can return a hymn whose section is hidden (each table has its own publish
/// rules), so rows whose parent is missing are left out instead of breaking the book.
Future<ImportSummary> importSnapshot(
  ContentDatabase db,
  ContentSnapshot snapshot,
) {
  return db.transaction(() async {
    await db.delete(db.hymnSections).go();
    await db.delete(db.hymns).go();
    await db.delete(db.hymnCategories).go();
    await db.delete(db.hymnals).go();
    await db.delete(db.readingParts).go();
    await db.delete(db.readings).go();
    await db.delete(db.church).go();

    final hymnalIds = _ids(snapshot.hymnals);
    final categoryIds = _ids(snapshot.categories);
    final hymns = [
      for (final r in snapshot.hymns)
        if (hymnalIds.contains(r['hymnal_id'])) r,
    ];
    final hymnIds = _ids(hymns);
    final sections = [
      for (final r in snapshot.sections)
        if (hymnIds.contains(r['hymn_id'])) r,
    ];
    final readingIds = _ids(snapshot.readings);
    final parts = [
      for (final r in snapshot.parts)
        if (readingIds.contains(r['reading_id'])) r,
    ];

    await db.batch((b) {
      b.insertAll(db.hymnals, [
        for (final r in snapshot.hymnals)
          HymnalsCompanion.insert(
            id: r['id']! as String,
            name: r['name']! as String,
            isDefault: Value(r['is_default'] as bool? ?? false),
            sortOrder: Value(_int(r['sort_order']) ?? 0),
          ),
      ]);
      b.insertAll(db.hymnCategories, [
        for (final r in snapshot.categories)
          HymnCategoriesCompanion.insert(
            id: r['id']! as String,
            name: r['name']! as String,
            sortOrder: Value(_int(r['sort_order']) ?? 0),
          ),
      ]);
      b.insertAll(db.hymns, [
        for (final r in hymns)
          HymnsCompanion.insert(
            id: r['id']! as String,
            hymnalId: r['hymnal_id']! as String,
            categoryId: Value(
              categoryIds.contains(r['category_id'])
                  ? r['category_id'] as String?
                  : null,
            ),
            number: Value(_int(r['number'])),
            title: r['title']! as String,
            firstLine: Value(_text(r['first_line'])),
            author: Value(_text(r['author'])),
            composer: Value(_text(r['composer'])),
            tuneName: Value(_text(r['tune_name'])),
            meter: Value(_text(r['meter'])),
            musicKey: Value(_text(r['music_key'])),
            scriptureRef: Value(_text(r['scripture_ref'])),
            choristerNotes: Value(_text(r['chorister_notes'])),
            isPublicDomain: Value(r['is_public_domain'] as bool? ?? true),
            sortOrder: Value(_int(r['sort_order']) ?? 0),
          ),
      ]);
      b.insertAll(db.hymnSections, [
        for (final r in sections)
          HymnSectionsCompanion.insert(
            id: r['id']! as String,
            hymnId: r['hymn_id']! as String,
            sectionType: r['section_type'] as String? ?? 'verse',
            sectionNumber: Value(_int(r['section_number'])),
            position: _int(r['position']) ?? 0,
            lyrics: r['lyrics'] as String? ?? '',
          ),
      ]);
      b.insertAll(db.readings, [
        for (final r in snapshot.readings)
          ReadingsCompanion.insert(
            id: r['id']! as String,
            kind: r['kind'] as String? ?? 'responsive_reading',
            number: Value(_int(r['number'])),
            title: r['title']! as String,
            scriptureRef: Value(_text(r['scripture_ref'])),
            isPublicDomain: Value(r['is_public_domain'] as bool? ?? true),
            sortOrder: Value(_int(r['sort_order']) ?? 0),
          ),
      ]);
      b.insertAll(db.readingParts, [
        for (final r in parts)
          ReadingPartsCompanion.insert(
            id: r['id']! as String,
            readingId: r['reading_id']! as String,
            position: _int(r['position']) ?? 0,
            number: Value(_int(r['number'])),
            speaker: Value(_text(r['speaker'])),
            body: r['body'] as String? ?? '',
            scriptureRef: Value(_text(r['scripture_ref'])),
          ),
      ]);
      if (snapshot.church.isNotEmpty) {
        final r = snapshot.church.first;
        final socials = r['socials'] as Map<Object?, Object?>?;
        b.insert(
          db.church,
          ChurchCompanion.insert(
            id: r['id']! as String,
            name: r['name']! as String,
            email: Value(_text(r['email'])),
            phone: Value(_text(r['phone'])),
            whatsapp: Value(_text(socials?['whatsapp'])),
            website: Value(_text(r['website'])),
            tagline: Value(_oneLine(r['tagline'])),
          ),
        );
      }
    });

    return ImportSummary(
      sections: snapshot.hymnals.length,
      hymns: hymns.length,
      verses: sections.length,
      readings: snapshot.readings.length,
      parts: parts.length,
      skipped:
          snapshot.hymns.length -
          hymns.length +
          snapshot.sections.length -
          sections.length +
          snapshot.parts.length -
          parts.length,
    );
  });
}

Set<Object?> _ids(List<ApiRow> rows) => {for (final r in rows) r['id']};

int? _int(Object? value) => (value as num?)?.toInt();

/// Blank text counts as missing, so the app never shows an empty label.
String? _text(Object? value) {
  final text = (value as String?)?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// [_text] on one line: line breaks and runs of spaces become a single space, so
/// the screen decides where a line such as the tagline wraps.
String? _oneLine(Object? value) =>
    _text(value)?.replaceAll(RegExp(r'\s+'), ' ');
