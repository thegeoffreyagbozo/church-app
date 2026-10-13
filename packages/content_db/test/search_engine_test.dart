import 'package:content_db/content_db.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late ContentDatabase db;
  late SearchEngine engine;

  setUp(() async {
    db = await sampleDatabase();
    engine = SearchEngine(db, ContentCatalog(db));
  });
  tearDown(() => db.close());

  List<String> ids(SearchResults results) => [
    for (final h in results.hits) h.id,
  ];

  group('numbers', () {
    test('a number opens that hymn in the default section', () async {
      final results = await engine.search('41');

      expect(ids(results), ['hymn-41']);
      expect(results.exactTop, isTrue);
      expect(results.hits.single.title, 'How Firm a Foundation');
      expect(
        results.hits.single.preview,
        'How firm a foundation, ye saints of the Lord',
      );
    });

    test(
      'lists the same number in other sections and readings after it',
      () async {
        final results = await engine.search('2');

        expect(ids(results), ['hymn-2', 'supp-2', 'reading-2']);
        expect(results.exactTop, isTrue);
        expect(results.hits[1].section!.name, 'Supplementary Hymns');
        expect(results.hits[2].readingKind, ReadingKind.callToWorship);
      },
    );

    test('says when the default section has no such number', () async {
      final results = await engine.search('999');

      expect(results.hits, isEmpty);
      expect(results.exactTop, isFalse);
      final missing = results.missing!;
      expect((missing.number, missing.sectionName), (999, 'Hymns'));
      expect((missing.lowest, missing.highest), (1, 41));
    });

    test(
      'still lists other matches when the default section lacks the number',
      () async {
        final results = await engine.search('3');

        expect(ids(results), ['reading-3']);
        expect(results.exactTop, isFalse);
        expect(results.missing!.number, 3);
      },
    );

    test('a section shortcut goes straight to that section', () async {
      final results = await engine.search('s2');

      expect(ids(results), ['supp-2']);
      expect(results.exactTop, isTrue);
    });

    test('a missing number in a section lists it elsewhere', () async {
      final results = await engine.search('S 7');

      expect(results.missing!.sectionName, 'Supplementary Hymns');
      expect((results.missing!.lowest, results.missing!.highest), (1, 2));
      expect(ids(results), ['hymn-7']);
    });

    test('R and a number open that reading', () async {
      final results = await engine.search('reading 3');

      expect(ids(results), ['reading-3']);
      expect(results.exactTop, isTrue);
    });

    test('a missing reading number gives the readings range', () async {
      final results = await engine.search('r9');

      expect(results.missing!.type, ItemType.reading);
      expect((results.missing!.lowest, results.missing!.highest), (1, 3));
    });
  });

  group('scripture', () {
    test('finds readings that cite the passage', () async {
      final results = await engine.search('Psalm 23');

      expect(results.hits.first.id, 'reading-1');
      expect(results.hits.first.match, MatchKind.scripture);
      expect(results.hits.first.snippet, 'Psalm 23');
    });

    test('matches a reference inside a collection', () async {
      final results = await engine.search('II Cor 13');

      expect(results.hits.first.id, 'reading-3');
      expect(results.hits.first.snippet, 'II Corinthians 13:14');
    });

    test('finds hymns that cite the passage', () async {
      final results = await engine.search('1 Corinthians 15:57');

      expect(ids(results), contains('supp-2'));
    });
  });

  group('words', () {
    test('matches word beginnings in titles', () async {
      final results = await engine.search('How fi');

      expect(results.hits.first.id, 'hymn-41');
      expect(results.hits.first.match, MatchKind.title);
      expect(
        results.hits.first.snippet,
        '${markStart}How$markEnd ${markStart}Firm$markEnd a Foundation',
      );
    });

    test('prefers the first line over the verse that starts with it', () async {
      final results = await engine.search('cleft');

      final hit = results.hits.single;
      expect(hit.id, 'hymn-1');
      expect(hit.match, MatchKind.firstLine);
    });

    test('names a verse that is not the first line', () async {
      final results = await engine.search('labours');

      final hit = results.hits.single;
      expect(hit.match, MatchKind.text);
      expect((hit.sectionType, hit.sectionNumber), (HymnSectionType.verse, 2));
      expect(hit.snippet, contains('${markStart}labours$markEnd'));
    });

    test('lists each item once, titles before text', () async {
      final results = await engine.search('grace');

      expect(ids(results), ['hymn-2', 'reading-3']);
      expect(results.hits.first.match, MatchKind.title);
      expect(results.hits.last.match, MatchKind.text);
    });

    test('finds credits last', () async {
      final results = await engine.search('ken');

      expect(results.hits.single.id, 'hymn-doxology');
      expect(results.hits.single.match, MatchKind.credits);
    });

    test('finds reading lines', () async {
      final results = await engine.search('green pastures');

      expect(results.hits.single.id, 'reading-1');
      expect(results.hits.single.readingKind, ReadingKind.responsiveReading);
    });

    test('ignores accents and apostrophes', () async {
      expect(ids(await engine.search("conqu'ring")), ['supp-2']);
      expect(ids(await engine.search('Thine is the glôry')), ['supp-2']);
    });

    test('finds nothing for unknown words', () async {
      final results = await engine.search('xylophone');

      expect(results.hits, isEmpty);
      expect(results.missing, isNull);
    });

    test('punctuation alone finds nothing', () async {
      final results = await engine.search('?!');

      expect(results.hits, isEmpty);
      expect(results.missing, isNull);
    });

    test('blank input finds nothing', () async {
      expect((await engine.search('  ')).hits, isEmpty);
    });
  });
}
