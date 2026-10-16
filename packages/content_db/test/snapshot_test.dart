import 'dart:convert';

import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late ContentDatabase db;

  setUp(() => db = ContentDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('imports every published row of the sample', () async {
    final summary = await importSnapshot(db, loadSample());

    expect(summary.sections, 3);
    expect(summary.hymns, 8);
    expect(summary.verses, 15);
    expect(summary.readings, 5);
    expect(summary.parts, 12);
    expect(summary.skipped, 0);
    expect(await db.select(db.hymns).get(), hasLength(8));
  });

  test(
    'leaves out rows whose section, hymn or reading is not published',
    () async {
      final sample = loadSample();
      final snapshot = ContentSnapshot(
        hymnals: sample.hymnals,
        categories: sample.categories,
        hymns: [
          ...sample.hymns,
          {'id': 'orphan', 'hymnal_id': 'hidden-section', 'title': 'Orphan'},
        ],
        sections: [
          ...sample.sections,
          {
            'id': 's',
            'hymn_id': 'unpublished-hymn',
            'position': 0,
            'lyrics': 'x',
          },
        ],
        readings: sample.readings,
        parts: [
          ...sample.parts,
          {
            'id': 'p',
            'reading_id': 'draft-reading',
            'position': 0,
            'body': 'x',
          },
        ],
        church: sample.church,
      );

      final summary = await importSnapshot(db, snapshot);

      expect(summary.skipped, 3);
      expect(summary.hymns, 8);
      final titles = (await db.select(db.hymns).get()).map((h) => h.title);
      expect(titles, isNot(contains('Orphan')));
    },
  );

  test('drops a topic that is not published', () async {
    final sample = loadSample();
    final snapshot = ContentSnapshot(
      hymnals: sample.hymnals,
      categories: const [],
      hymns: sample.hymns,
      sections: sample.sections,
      readings: sample.readings,
      parts: sample.parts,
      church: sample.church,
    );

    await importSnapshot(db, snapshot);

    final hymn = await (db.select(
      db.hymns,
    )..where((h) => h.id.equals('hymn-break-bread'))).getSingle();
    expect(hymn.categoryId, isNull);
  });

  test("reads the WhatsApp number from the church's socials", () async {
    await importSnapshot(db, loadSample());

    final church = await db.select(db.church).getSingle();
    expect(church.name, 'Grace Chapel');
    expect(church.whatsapp, '+233 20 000 0000');
  });

  /// The sample with its church row changed by [change].
  ContentSnapshot sampleWithChurch(ApiRow Function(ApiRow row) change) {
    final sample = loadSample();
    return ContentSnapshot(
      hymnals: sample.hymnals,
      categories: sample.categories,
      hymns: sample.hymns,
      sections: sample.sections,
      readings: sample.readings,
      parts: sample.parts,
      church: [change(sample.church.single)],
    );
  }

  test("copies the church's tagline, keeping its line break", () async {
    await importSnapshot(
      db,
      sampleWithChurch(
        (row) => {...row, 'tagline': 'Where all are welcome\nin Christ'},
      ),
    );

    final church = await db.select(db.church).getSingle();
    expect(church.tagline, 'Where all are welcome\nin Christ');
  });

  test('stores a blank tagline as none', () async {
    await importSnapshot(
      db,
      sampleWithChurch((row) => {...row, 'tagline': '  '}),
    );

    final church = await db.select(db.church).getSingle();
    expect(church.tagline, isNull);
  });

  test("asks the API for the church's tagline", () {
    expect(snapshotColumns['church']!.split(','), contains('tagline'));
  });

  test('importing again replaces the previous content', () async {
    await importSnapshot(db, loadSample());
    final smaller = ContentSnapshot(
      hymnals: loadSample().hymnals,
      categories: const [],
      hymns: loadSample().hymns.take(1).toList(),
      sections: const [],
      readings: const [],
      parts: const [],
      church: const [],
    );

    await importSnapshot(db, smaller);

    expect(await db.select(db.hymns).get(), hasLength(1));
    expect(await db.select(db.readings).get(), isEmpty);
  });

  test('round-trips through JSON', () {
    final sample = loadSample();

    final copy = ContentSnapshot.parse(jsonEncode(sample.toJson()));

    expect(copy.hymns, hasLength(sample.hymns.length));
    expect(copy.church.single['name'], 'Grace Chapel');
  });
}
