import 'ids.dart';
import 'model.dart';
import 'music.dart';
import 'public_domain.dart';

/// One row to insert or update: its table and its column values.
class Row {
  const Row(this.table, this.values);
  final String table;
  final Map<String, Object?> values;
}

/// Soft-deletes the rows of [table] under [parentId] at positions >= [keep], so content
/// removed in a corrected batch disappears instead of lingering.
class Cleanup {
  const Cleanup(
    this.table,
    this.parentColumn,
    this.parentId,
    this.keep, {
    this.orderColumn = 'position',
    this.kind,
  });
  final String table;
  final String parentColumn;
  final String parentId;
  final int keep;

  /// The column that orders the children (`sort_order` for sheet music).
  final String orderColumn;

  /// Only children of this `kind`, so that other kinds (a hymn's audio, say) stay.
  final String? kind;
}

/// Everything one import writes, in dependency order.
class ImportPlan {
  ImportPlan(this.rows, this.cleanups);
  final List<Row> rows;
  final List<Cleanup> cleanups;

  Iterable<Row> rowsOf(String table) => rows.where((r) => r.table == table);
}

final _punctuation = RegExp(r'[,;:.!?]');
final _trailing = RegExp(r'[\s,;:]+$');

/// The first line of [lyrics] for lists and search, without trailing punctuation. Verses
/// printed as one paragraph are cut at the last punctuation within 60 characters.
String firstLineOf(String lyrics) {
  var line = lyrics.split('\n').first.trim();
  if (line.length > 60) {
    final head = line.substring(0, 60);
    final cut = head.lastIndexOf(_punctuation);
    final space = head.lastIndexOf(' ');
    line = cut > 0
        ? head.substring(0, cut)
        : head.substring(0, space > 0 ? space : 60);
  }
  return line.replaceFirst(_trailing, '');
}

/// Turns a parsed [book] into the rows to write.
///
/// Row ids derive from natural keys (section and number, or kind and title), so importing
/// a corrected batch again updates the same rows. Protected or unconfirmed content is left
/// unpublished unless [publishAll]; drafts are never published. [music] adds sheet-music
/// rows; then every hymn also cleans up pieces it no longer has.
ImportPlan planImport(
  Book book, {
  required int currentYear,
  bool publishAll = false,
  String defaultSection = 'Hymns',
  String language = 'en',
  List<MusicPiece>? music,
}) {
  final rows = <Row>[];
  final cleanups = <Cleanup>[];
  String hymnalId(String section) => stableId('hymnal/$language/$section');
  String categoryId(String topic) =>
      stableId('category/${topic.toLowerCase()}');

  for (final (i, section) in book.sections.indexed) {
    rows.add(
      Row('hymnals', {
        'id': hymnalId(section),
        'name': section,
        'language': language,
        'is_default': section == defaultSection,
        'sort_order': i,
        'published': true,
      }),
    );
  }

  final topics = {
    for (final h in book.hymns)
      if (h.topic != null) h.topic!,
  };
  for (final topic in topics) {
    rows.add(
      Row('hymn_categories', {
        'id': categoryId(topic),
        'hymnal_id': null,
        'key': _key(topic),
        'name': topic,
      }),
    );
  }

  String groupId(String section, Grouping g) => stableId(
        'category/$language/${section.toLowerCase()}/'
        '${(g.part ?? '').toLowerCase()}/${g.name.toLowerCase()}',
      );
  final groups = <String, (String, Grouping)>{};
  for (final h in book.hymns) {
    final g = h.group;
    if (g != null) {
      groups.putIfAbsent(groupId(h.section, g), () => (h.section, g));
    }
  }
  for (final (i, MapEntry(key: id, value: (section, g)))
      in groups.entries.indexed) {
    rows.add(
      Row('hymn_categories', {
        'id': id,
        'hymnal_id': hymnalId(section),
        'key': _key(g.part == null ? g.name : '${g.part} ${g.name}'),
        'name': g.name,
        'theme': g.part,
        'sort_order': i,
      }),
    );
  }

  final positionInSection = <String, int>{};
  for (final h in book.hymns) {
    final key =
        'hymn/$language/${h.section}/${h.number ?? h.title!.toLowerCase()}';
    final id = stableId(key);
    final credits = [h.words, h.music, h.arranged, h.translated]
        .whereType<String>()
        .toList();
    final free = isPublicDomain(
      credits,
      currentYear: currentYear,
      copyright: h.copyright,
    );
    rows.add(
      Row('hymns', {
        'id': id,
        'hymnal_id': hymnalId(h.section),
        'category_id': h.group != null
            ? groupId(h.section, h.group!)
            : h.topic == null
                ? null
                : categoryId(h.topic!),
        'number': h.number,
        'title': h.title,
        'first_line': firstLineOf(
          h.sections.firstWhere((s) => s.lyrics.isNotEmpty).lyrics,
        ),
        'author': _credit(h.words, h.translated, 'translated by'),
        'composer': _credit(h.music, h.arranged, 'arranged by'),
        'tune_name': h.tune,
        'meter': h.meter,
        'music_key': h.musicKey,
        'scripture_ref': h.scripture,
        'language': language,
        'copyright': h.copyright,
        'is_public_domain': free,
        'chorister_notes':
            h.alsoSungTo == null ? null : 'Also sung to: ${h.alsoSungTo}',
        'sort_order': positionInSection.update(
          h.section,
          (p) => p + 1,
          ifAbsent: () => 0,
        ),
        'published': !h.draft && (free || publishAll),
      }),
    );
    for (final (i, s) in h.sections.indexed) {
      rows.add(
        Row('hymn_sections', {
          'id': stableId('$key/section/$i'),
          'hymn_id': id,
          'section_type': s.type,
          'section_number': s.number,
          'position': i,
          'lyrics': s.lyrics,
        }),
      );
    }
    cleanups.add(Cleanup('hymn_sections', 'hymn_id', id, h.sections.length));
    if (music != null) {
      final hymnKey = '${h.section}/${h.number ?? h.title!.toLowerCase()}';
      final pieces = [
        for (final m in music)
          if (m.hymnKey == hymnKey) m,
      ]..sort((a, b) => a.part.compareTo(b.part));
      for (final m in pieces) {
        rows.add(
          Row('hymn_assets', {
            'id': stableId('$key/music/${m.part}'),
            'hymn_id': id,
            'kind': 'sheet_music_image',
            'storage_bucket': 'sheet-music',
            'storage_path': m.path,
            'page': m.page,
            'mime': 'image/png',
            'sort_order': m.part - 1,
          }),
        );
      }
      cleanups.add(
        Cleanup(
          'hymn_assets',
          'hymn_id',
          id,
          pieces.length,
          orderColumn: 'sort_order',
          kind: 'sheet_music_image',
        ),
      );
    }
  }

  for (final (i, r) in book.readings.indexed) {
    final key =
        'reading/$language/${r.number ?? '${r.kind}/${r.title!.toLowerCase()}'}';
    final id = stableId(key);
    // Readings are scripture or church texts: free unless a Copyright label says otherwise.
    final free = r.copyright == null ||
        r.copyright!.trim().toLowerCase() == 'public domain';
    rows.add(
      Row('readings', {
        'id': id,
        'kind': r.kind,
        'number': r.number,
        'title': r.title,
        'scripture_ref': r.scripture,
        'language': language,
        'copyright': r.copyright,
        'is_public_domain': free,
        'sort_order': i,
        'published': !r.draft && (free || publishAll),
      }),
    );
    for (final (j, p) in r.parts.indexed) {
      rows.add(
        Row('reading_parts', {
          'id': stableId('$key/part/$j'),
          'reading_id': id,
          'position': j,
          'number': p.number,
          'speaker': p.speaker,
          'body': p.body,
          'scripture_ref': p.ref,
        }),
      );
    }
    cleanups.add(Cleanup('reading_parts', 'reading_id', id, r.parts.length));
  }

  return ImportPlan(rows, cleanups);
}

/// A category key such as "jesus-our-savior-his-birth".
String _key(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

/// "Words; translated by X" or "Music; arranged by Y", whichever parts are printed.
String? _credit(String? main, String? extra, String how) {
  if (extra == null) return main;
  return main == null ? '$how $extra' : '$main; $how $extra';
}
