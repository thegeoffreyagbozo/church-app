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
const hisBirthId = 'd980a9eb-54f8-5732-8cb6-392b638a50c6';
const holySpiritId = 'b8cef61e-3b5d-5672-a058-bdff462c17e6';
const hymn85Id = 'afac7e8f-966a-5c92-9f75-a94d3319e4e1';
const hymn158Id = '2f1bed23-eef3-5b4b-93d9-4d069ac72ae6';
const hymn267Music1Id = '6c420fa3-9739-5523-8a77-6e771c0cd03e';
const hymn267Music2Id = '54aa6c6f-a3f1-56a9-95f2-79e347184cbd';

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

    test('a group becomes a category of its section, in book order', () {
      final p = plan('''
SECTION Hymns
GROUP Jesus Our Savior / His Birth
HYMN 85
Title: Joy to the World
Words: Isaac Watts, 1674-1748

1
Joy to the world! the Lord is come;

GROUP The Holy Spirit
HYMN 158
Title: Holy Ghost, with Light Divine
Words: Andrew Reed, 1787-1862

1
Holy Ghost, with light divine,
''');
      final birth = row(p, 'hymn_categories', hisBirthId);
      expect(birth['hymnal_id'], hymnsId);
      expect(birth['theme'], 'Jesus Our Savior');
      expect(birth['name'], 'His Birth');
      expect(birth['key'], 'jesus-our-savior-his-birth');
      expect(birth['sort_order'], 0);
      final spirit = row(p, 'hymn_categories', holySpiritId);
      expect(spirit['theme'], isNull);
      expect(spirit['sort_order'], 1);
      expect(row(p, 'hymns', hymn85Id)['category_id'], hisBirthId);
      expect(row(p, 'hymns', hymn158Id)['category_id'], holySpiritId);
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

  test(
    'music pieces become sheet-music rows of their hymn, cleaned up per hymn',
    () {
      final p = planImport(
        parseSources([const Source('t.txt', hymn267)]),
        currentYear: 2026,
        music: const [
          MusicPiece('Hymns', '267', 1, 'hymns/267-1.png', 271, 1),
          MusicPiece('Hymns', '267', 2, 'hymns/267-2.png', 272, 2),
        ],
      );
      final first = row(p, 'hymn_assets', hymn267Music1Id);
      expect(first['hymn_id'], hymn267Id);
      expect(first['kind'], 'sheet_music_image');
      expect(first['storage_bucket'], 'sheet-music');
      expect(first['storage_path'], 'hymns/267-1.png');
      expect(first['page'], 271);
      expect(first['mime'], 'image/png');
      expect(first['sort_order'], 0);
      expect(row(p, 'hymn_assets', hymn267Music2Id)['sort_order'], 1);
      final cleanup = p.cleanups.singleWhere((c) => c.table == 'hymn_assets');
      expect(
        (cleanup.parentId, cleanup.keep, cleanup.orderColumn),
        (hymn267Id, 2, 'sort_order'),
      );
      // Only sheet music: other files of the hymn, such as audio, stay.
      expect(cleanup.kind, 'sheet_music_image');
    },
  );

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

  group('notation', () {
    Book book() => parseSources(
          [
            const Source(
              'b.txt',
              'SECTION Hymns\nHYMN 8\nTitle: All People\n\n1\nAll people\n',
            ),
          ],
          defaultSection: 'Hymns',
        );

    test('a hymn with notation gets one musicxml asset row and an upload', () {
      final plan = planImport(
        book(),
        currentYear: 2026,
        notation: [const NotationEntry('Hymns', '8', '/n/008.mxl', 1)],
      );
      final hymnId = plan.rowsOf('hymns').single.values['id']! as String;
      final row = plan.rowsOf('hymn_assets').single.values;
      expect(row['kind'], 'musicxml');
      expect(row['storage_path'], '$hymnId/notation.mxl');
      expect(row['hymn_id'], hymnId);
      expect(plan.uploads.single.file, '/n/008.mxl');
      expect(plan.uploads.single.path, '$hymnId/notation.mxl');
    });

    test('re-importing cleans up only notation, never the scanned music', () {
      final plan = planImport(book(), currentYear: 2026, notation: const []);
      final cleanup =
          plan.cleanups.singleWhere((c) => c.table == 'hymn_assets');
      expect(cleanup.kind, 'musicxml');
      expect(cleanup.keep, 0);
    });

    test('without a notation map nothing about notation is written', () {
      final plan = planImport(book(), currentYear: 2026);
      expect(plan.rowsOf('hymn_assets'), isEmpty);
      expect(plan.cleanups.where((c) => c.table == 'hymn_assets'), isEmpty);
      expect(plan.uploads, isEmpty);
    });
  });
}
