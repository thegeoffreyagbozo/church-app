import 'package:content_db/content_db.dart';
import 'package:test/test.dart';

const hymns = Section(
  id: 'h',
  name: 'Hymns',
  isDefault: true,
  count: 571,
  lowestNumber: 1,
  highestNumber: 571,
);
const supplementary = Section(
  id: 's',
  name: 'Supplementary Hymns',
  isDefault: false,
  count: 20,
  lowestNumber: 1,
  highestNumber: 20,
);
const serviceMusic = Section(
  id: 'm',
  name: 'Service Music',
  isDefault: false,
  count: 9,
);
const sections = [hymns, supplementary, serviceMusic];

void main() {
  group('interpretQuery', () {
    test('digits mean a number in the default section', () {
      expect(
        interpretQuery('268', sections),
        isA<NumberInput>().having((i) => i.number, 'number', 268),
      );
      expect(interpretQuery(' #12 ', sections), isA<NumberInput>());
    });

    test('a section letter and a number go to that section', () {
      for (final typed in ['S2', 's 2', 'S. 2']) {
        final input = interpretQuery(typed, sections);
        expect(input, isA<SectionNumberInput>(), reason: typed);
        input as SectionNumberInput;
        expect((input.section.name, input.number), ('Supplementary Hymns', 2));
      }
    });

    test('the start of a section name works like its letter', () {
      final input =
          interpretQuery('hymn number 268', sections) as SectionNumberInput;
      expect((input.section, input.number), (hymns, 268));
      expect(
        (interpretQuery('supp 2', sections) as SectionNumberInput).section,
        supplementary,
      );
    });

    test('reads numbers printed with leading zeros', () {
      expect(
        interpretQuery('001', sections),
        isA<NumberInput>().having((i) => i.number, 'number', 1),
      );
      final input = interpretQuery('S001', sections) as SectionNumberInput;
      expect((input.section, input.number), (supplementary, 1));
    });

    test('R or reading means readings', () {
      for (final typed in ['R5', 'r 5', 'reading 5', 'Readings 5']) {
        expect(
          interpretQuery(typed, sections),
          isA<ReadingNumberInput>().having((i) => i.number, 'number', 5),
          reason: typed,
        );
      }
    });

    test('a scripture reference is recognised', () {
      final input = interpretQuery('Psalm 23', sections) as ScriptureInput;
      expect(input.ref, const BibleRef(19, 23));
      expect(input.text, 'psalm 23');
      expect(interpretQuery('ps 23', sections), isA<ScriptureInput>());
    });

    test('anything else is a word search', () {
      expect(
        interpretQuery('How fi', sections),
        isA<WordsInput>().having((i) => i.text, 'text', 'how fi'),
      );
      expect(interpretQuery('x 2', sections), isA<WordsInput>());
    });

    test('blank input searches nothing', () {
      expect(interpretQuery('   ', sections), isA<EmptyInput>());
    });
  });

  group('sectionLetters', () {
    test('gives each numbered section its unique first letter', () {
      expect(sectionLetters(sections), {'h': hymns, 's': supplementary});
    });

    test('gives no letter when two numbered sections share it', () {
      const songs = Section(
        id: 'x',
        name: 'Songs of Zion',
        isDefault: false,
        count: 5,
        lowestNumber: 1,
        highestNumber: 5,
      );
      expect(sectionLetters([...sections, songs]), {'h': hymns});
    });

    test('keeps R for readings', () {
      const responses = Section(
        id: 'r',
        name: 'Responses',
        isDefault: false,
        count: 3,
        lowestNumber: 1,
        highestNumber: 3,
      );
      expect(sectionLetters([hymns, responses]), {'h': hymns});
    });
  });

  group('ftsMatchQuery', () {
    test('matches the start of every word', () {
      expect(ftsMatchQuery('How fi'), '"how"* "fi"*');
    });

    test("splits words the way the index does (o'er is two words)", () {
      expect(ftsMatchQuery("o'er death"), '"o"* "er"* "death"*');
    });

    test('is null without words', () {
      expect(ftsMatchQuery(' !? '), isNull);
    });
  });
}
