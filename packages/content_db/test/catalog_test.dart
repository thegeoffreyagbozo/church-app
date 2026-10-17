import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late ContentDatabase db;
  late ContentCatalog catalog;

  setUp(() async {
    db = await sampleDatabase();
    catalog = ContentCatalog(db);
  });
  tearDown(() => db.close());

  test('lists sections in book order with their number ranges', () async {
    final sections = await catalog.sections();

    expect(sections.map((s) => s.name), [
      'Service Music',
      'Hymns',
      'Supplementary Hymns',
    ]);
    final hymns = sections[1];
    expect(hymns.isDefault, isTrue);
    expect(hymns.count, 4);
    expect((hymns.lowestNumber, hymns.highestNumber), (1, 41));
    expect(sections[0].isNumbered, isFalse);
    expect(sections.where((s) => s.isDefault), hasLength(1));
  });

  test(
    'falls back to the first numbered section when none is marked default',
    () async {
      await db.customStatement('UPDATE hymnals SET is_default = 0');

      final sections = await ContentCatalog(db).sections();

      expect(sections.singleWhere((s) => s.isDefault).name, 'Hymns');
    },
  );

  test('lists a numbered section by number', () async {
    final hymns = await catalog.hymnsIn('section-hymns');

    expect(hymns.map((h) => h.number), [1, 2, 7, 41]);
    expect(hymns.first.firstLine, 'Rock of Ages, cleft for me');
  });

  test('lists an unnumbered section in book order with topics', () async {
    final hymns = await catalog.hymnsIn('section-service');

    expect(hymns.map((h) => h.title), [
      'Doxology',
      'Let Us Break Bread Together',
    ]);
    expect(hymns.last.topic, 'Communion');
  });

  test('a grouped section gives each hymn its contents heading', () async {
    final hymns = await catalog.hymnsIn('section-hymns');

    expect(
      [for (final h in hymns) (h.number, h.group?.part, h.group?.name)],
      [
        (1, 'Hymns of Worship', 'General'),
        (2, 'Hymns of Worship', 'General'),
        (7, null, 'The Holy Spirit'),
        (41, 'The Christian Experience', 'Songs of Assurance and Trust'),
      ],
    );
    expect(hymns.every((h) => h.topic == null), isTrue);
  });

  test('a topic shared by the whole book is not a contents heading', () async {
    final hymns = await catalog.hymnsIn('section-service');

    expect(hymns.last.topic, 'Communion');
    expect(hymns.last.group, isNull);
  });

  test('a hymn lists its music pieces in order, with their sizes', () async {
    final hymn = await catalog.hymn('hymn-41');

    expect(
      [for (final m in hymn!.music) (m.id, m.width, m.height)],
      [('music-41-1', 1200, 900), ('music-41-2', 1200, 500)],
    );
    expect((await catalog.hymn('hymn-7'))!.music, isEmpty);
  });

  test('a hymn carries its contents heading', () async {
    final hymn = await catalog.hymn('hymn-41');

    expect(hymn!.group?.name, 'Songs of Assurance and Trust');
    expect(hymn.group?.partName, 'The Christian Experience');
    expect(hymn.topic, isNull);
  });

  test('loads a hymn with its verses, chorus and music details', () async {
    final hymn = (await catalog.hymn('supp-1'))!;

    expect(hymn.section.name, 'Supplementary Hymns');
    expect(hymn.texts.map((t) => (t.type, t.number)), [
      (HymnSectionType.verse, 1),
      (HymnSectionType.chorus, null),
      (HymnSectionType.verse, 2),
    ]);
    expect(hymn.tuneName, 'Assurance');
    expect(hymn.meter, '9.10.9.9 with refrain');
  });

  test(
    'links the tunes a hymn is also sung to when the app has them',
    () async {
      final hymn = (await catalog.hymn('hymn-41'))!;

      expect(hymn.alsoSungTo.map((a) => (a.tune, a.number, a.hymnId)), [
        ('Adeste Fideles', 100, null),
        ('Toplady', 1, 'hymn-1'),
      ]);
    },
  );

  test('is null for a hymn that is not in the book', () async {
    expect(await catalog.hymn('nope'), isNull);
  });

  test('lists readings by number, then creeds and covenants', () async {
    final readings = await catalog.readings();

    expect(readings.map((r) => r.number), [1, 2, 3, null, null]);
    expect(readings.last.kind, ReadingKind.covenant);
    expect(readings.last.preview, startsWith('Having been led'));
  });

  test('loads a reading with its parts in order', () async {
    final reading = (await catalog.reading('reading-1'))!;

    expect(reading.parts.map((p) => p.speaker), [
      ReadingSpeaker.leader,
      ReadingSpeaker.people,
      ReadingSpeaker.leader,
      ReadingSpeaker.all,
    ]);
    expect(reading.readTogether, isFalse);
    expect((await catalog.reading('reading-creed'))!.readTogether, isTrue);
  });

  test('reads the church profile', () async {
    final church = (await catalog.church())!;

    expect(church.name, 'Grace Chapel');
    expect(church.email, 'hello@example.church');
    expect(church.tagline, isNull);
  });

  test("reads the church's tagline", () async {
    await db
        .update(db.church)
        .write(const ChurchCompanion(tagline: Value('Where all\nare welcome')));

    expect((await catalog.church())!.tagline, 'Where all\nare welcome');
  });

  test(
    'lists recently opened items newest first, skipping removed ones',
    () async {
      var minute = 0;
      final user = UserData(
        db,
        clock: () => DateTime.utc(2026, 1, 1, 9, minute++),
      );
      await user.markOpened(ItemType.hymn, 'hymn-41');
      await user.markOpened(ItemType.reading, 'reading-3');
      await user.markOpened(ItemType.hymn, 'supp-1');
      await user.markOpened(ItemType.hymn, 'gone');

      final recent = await catalog.recentlyOpened();

      expect(recent.map((r) => r.id), ['supp-1', 'reading-3', 'hymn-41']);
      expect(recent.first.section!.name, 'Supplementary Hymns');
      expect(recent[1].readingKind, ReadingKind.benediction);
      expect(recent[1].preview, startsWith('The Lord bless thee'));
    },
  );
}
