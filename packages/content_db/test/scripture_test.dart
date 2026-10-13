import 'package:content_db/content_db.dart';
import 'package:test/test.dart';

void main() {
  group('parseBibleRef', () {
    test('reads a book and chapter', () {
      expect(parseBibleRef('Psalm 23'), const BibleRef(19, 23));
      expect(parseBibleRef('psalms 23'), const BibleRef(19, 23));
      expect(parseBibleRef('Ps 23'), const BibleRef(19, 23));
    });

    test('reads a verse', () {
      expect(parseBibleRef('John 3:16'), const BibleRef(43, 3, 16));
      expect(parseBibleRef('john 3.16'), const BibleRef(43, 3, 16));
    });

    test('reads numbered books written several ways', () {
      const secondCor13 = BibleRef(47, 13);
      expect(parseBibleRef('II Cor 13'), secondCor13);
      expect(parseBibleRef('2 Corinthians 13'), secondCor13);
      expect(parseBibleRef('2cor 13'), secondCor13);
      expect(parseBibleRef('second corinthians 13'), secondCor13);
      expect(parseBibleRef('1 John 4:8'), const BibleRef(62, 4, 8));
    });

    test('accepts the start of a book name when only one book fits', () {
      expect(parseBibleRef('Corin 13'), isNull); // 1 or 2 Corinthians?
      expect(parseBibleRef('Revel 21'), const BibleRef(66, 21));
      expect(parseBibleRef('Isaiah 53'), const BibleRef(23, 53));
      expect(parseBibleRef('Song of Solomon 2'), const BibleRef(22, 2));
    });

    test('is null for words, bare numbers and unknown books', () {
      expect(parseBibleRef('how firm'), isNull);
      expect(parseBibleRef('268'), isNull);
      expect(parseBibleRef('Hymn 268'), isNull);
      expect(parseBibleRef('Ju 3'), isNull);
    });
  });

  group('parseScriptureRefs', () {
    test('reads a verse range', () {
      expect(parseScriptureRefs('Numbers 6:24-26'), [
        const ScriptureSpan(4, 6, 24, 6, 26),
      ]);
    });

    test('reads a whole chapter', () {
      expect(parseScriptureRefs('Psalm 23'), [
        const ScriptureSpan(19, 23, null, 23, null),
      ]);
    });

    test('carries the book across semicolons', () {
      expect(parseScriptureRefs('Psalm 34:3; 66:1-4; 67:3-5'), [
        const ScriptureSpan(19, 34, 3, 34, 3),
        const ScriptureSpan(19, 66, 1, 66, 4),
        const ScriptureSpan(19, 67, 3, 67, 5),
      ]);
    });

    test('carries the chapter across commas', () {
      expect(parseScriptureRefs('Romans 12:1-2, 9-10'), [
        const ScriptureSpan(45, 12, 1, 12, 2),
        const ScriptureSpan(45, 12, 9, 12, 10),
      ]);
    });

    test('reads a range across chapters', () {
      expect(parseScriptureRefs('John 3:16-4:2'), [
        const ScriptureSpan(43, 3, 16, 4, 2),
      ]);
    });

    test('reads Roman numerals for numbered books', () {
      expect(parseScriptureRefs('II Corinthians 13:14'), [
        const ScriptureSpan(47, 13, 14, 13, 14),
      ]);
    });

    test('skips what it cannot read', () {
      expect(parseScriptureRefs('Traditional'), isEmpty);
      expect(parseScriptureRefs('after Psalm'), isEmpty);
    });
  });

  group('ScriptureSpan.covers', () {
    const span = ScriptureSpan(47, 13, 11, 13, 14);

    test('a chapter covers every verse in it', () {
      expect(span.covers(const BibleRef(47, 13)), isTrue);
      expect(span.covers(const BibleRef(47, 13, 14)), isTrue);
    });

    test('a verse outside the range or another book does not match', () {
      expect(span.covers(const BibleRef(47, 13, 15)), isFalse);
      expect(span.covers(const BibleRef(47, 12)), isFalse);
      expect(span.covers(const BibleRef(46, 13)), isFalse);
    });
  });
}
