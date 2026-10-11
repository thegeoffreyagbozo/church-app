import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

ImportPlan plan(String text, {bool publishAll = false}) => planImport(
      parseSources([Source('t.txt', text)]),
      currentYear: 2026,
      publishAll: publishAll,
    );

Map<String, Object?> row(ImportPlan p, String table, String id) =>
    p.rows.singleWhere((r) => r.table == table && r.values['id'] == id).values;

// Ids below were computed independently with Python's uuid.uuid5 and the importer's
// namespace, from keys like "hymn/en/Hymns/267".
const hymnsId = '91be5deb-0b63-57a8-ae89-73daa5a168d3';
const serviceMusicId = 'cc95e830-9d21-5471-b488-79ddc1d8f3d1';
const hymn267Id = 'adc30a52-ba79-5b60-aea7-82989017a58b';
const hymn267Verse1Id = '5009afcc-f354-52b5-b484-ddf178687192';
const doxologyId = '94a082b9-7e85-59a2-8433-a7adb90b6194';
const communionId = '9135a439-31ab-5dfa-9fa0-2dc8cf675fac';
const benedictionsId = '1418878a-1bef-52b8-aab8-71e5a51c4e8c';
const benedictionsPart2Id = 'aaa3f5d2-739c-5535-8549-e36e944bad93';
const covenantId = '70163509-9b99-5c9e-9c0d-d9655917c6bd';

const hymn267 = '''
SECTION Hymns
HYMN 267
Title: All Things Work Out for Good
Tune: Ortonville
Words: Thomas Hastings, 1784-1872
Music: John W. Peterson, 1921-
Arranged: John W. Peterson, 1921-

1
All things work out for good, we know - such is God's great design;

2
This is the faith that keeps me still,
no matter what the test,
''';

const doxology = '''
SECTION Service Music
HYMN
Title: Doxology
Words: Thomas Ken, 1637-1711

Praise God, from whom all blessings flow;
''';

void main() {
  group('firstLineOf', () {
    test('stops at the end of the first printed line, without its punctuation',
        () {
      expect(
        firstLineOf('Praise God, from whom all blessings flow;\nPraise Him'),
        'Praise God, from whom all blessings flow',
      );
    });

    test('cuts a paragraph verse at the last punctuation within 60 characters',
        () {
      expect(
        firstLineOf(
          'How firm a foundation, ye saints of the Lord, is laid for your faith in His '
          'excellent Word!',
        ),
        'How firm a foundation, ye saints of the Lord',
      );
    });
  });

  group('hymns', () {
    test('a hymn row carries its printed details under a stable id', () {
      final h = row(plan(hymn267), 'hymns', hymn267Id);
      expect(h['hymnal_id'], hymnsId);
      expect(h['number'], 267);
      expect(h['title'], 'All Things Work Out for Good');
      expect(h['first_line'], 'All things work out for good');
      expect(h['author'], 'Thomas Hastings, 1784-1872');
      expect(
        h['composer'],
        'John W. Peterson, 1921-; arranged by John W. Peterson, 1921-',
      );
      expect(h['tune_name'], 'Ortonville');
    });

    test('its verses become sections with stable ids and positions', () {
      final p = plan(hymn267);
      final v1 = row(p, 'hymn_sections', hymn267Verse1Id);
      expect(v1['hymn_id'], hymn267Id);
      expect(v1['section_type'], 'verse');
      expect(v1['section_number'], 1);
      expect(v1['position'], 0);
      expect(
        v1['lyrics'],
        "All things work out for good, we know - such is God's great design;",
      );
      expect(p.rowsOf('hymn_sections'), hasLength(2));
    });

    test('a protected hymn stays unpublished unless publishAll is set', () {
      expect(
        row(plan(hymn267), 'hymns', hymn267Id)['is_public_domain'],
        isFalse,
      );
      expect(row(plan(hymn267), 'hymns', hymn267Id)['published'], isFalse);
      expect(
        row(plan(hymn267, publishAll: true), 'hymns', hymn267Id)['published'],
        isTrue,
      );
    });

    test('a public-domain hymn is published, but a draft never is', () {
      final d = row(plan(doxology), 'hymns', doxologyId);
      expect(d['number'], isNull);
      expect(d['is_public_domain'], isTrue);
      expect(d['published'], isTrue);
      final draft = doxology.replaceFirst('Words:', 'Status: draft\nWords:');
      expect(
        row(plan(draft, publishAll: true), 'hymns', doxologyId)['published'],
        isFalse,
      );
    });

    test('sections become hymnals in book order, with the main one as default',
        () {
      final p = plan('$doxology\n$hymn267');
      final serviceMusic = row(p, 'hymnals', serviceMusicId);
      expect(serviceMusic['name'], 'Service Music');
      expect(serviceMusic['sort_order'], 0);
      expect(serviceMusic['is_default'], isFalse);
      final hymns = row(p, 'hymnals', hymnsId);
      expect(hymns['sort_order'], 1);
      expect(hymns['is_default'], isTrue);
      expect(hymns['published'], isTrue);
    });

    test('a topic becomes a shared category that its hymns point to', () {
      final p = plan('''
SECTION Service Music
TOPIC Communion
HYMN
Title: Let Us Break Bread Together
Words: Traditional

1
Let us break bread together on our knees.
''');
      final c = row(p, 'hymn_categories', communionId);
      expect(c['key'], 'communion');
      expect(c['name'], 'Communion');
      expect(c['hymnal_id'], isNull);
      expect(p.rowsOf('hymns').single.values['category_id'], communionId);
    });
  });

  group('readings', () {
    test('a collection keeps each part\'s number, reader and reference', () {
      final p = plan('''
READING 60
Title: Benedictions
Kind: benedictions

1. The grace of the Lord Jesus Christ be with you all. Amen.
Ref: II Corinthians 13:14

2. Now unto the King eternal be honour and glory. Amen.
Ref: I Timothy 1:17
''');
      final r = row(p, 'readings', benedictionsId);
      expect(r['kind'], 'benediction');
      expect(r['number'], 60);
      expect(r['is_public_domain'], isTrue);
      expect(r['published'], isTrue);
      final part = row(p, 'reading_parts', benedictionsPart2Id);
      expect(part['reading_id'], benedictionsId);
      expect(part['position'], 1);
      expect(part['number'], 2);
      expect(part['speaker'], 'leader');
      expect(
        part['body'],
        'Now unto the King eternal be honour and glory. Amen.',
      );
      expect(part['scripture_ref'], 'I Timothy 1:17');
    });

    test('an unnumbered reading is keyed by its kind and title', () {
      final p = plan(
        'COVENANT\nTitle: The Church Covenant\n\nWe covenant together.\n',
      );
      expect(row(p, 'readings', covenantId)['number'], isNull);
    });
  });

  test('each hymn and reading soft-deletes the children it no longer has', () {
    final p = plan(
      '$hymn267\nCOVENANT\nTitle: The Church Covenant\n\nWe covenant together.\n',
    );
    expect(
      [
        for (final c in p.cleanups)
          '${c.table} ${c.parentColumn} ${c.parentId} ${c.keep}',
      ],
      [
        'hymn_sections hymn_id $hymn267Id 2',
        'reading_parts reading_id $covenantId 1',
      ],
    );
  });
}
