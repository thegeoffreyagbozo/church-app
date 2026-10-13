import 'package:content_db/content_db.dart';
import 'package:test/test.dart';

void main() {
  group('previewLine', () {
    test('takes the first line without markup', () {
      expect(
        previewLine('**We engage, therefore:**\n- to **walk** together'),
        'We engage, therefore:',
      );
    });

    test('skips blank lines and bullet dashes', () {
      expect(previewLine('\n- to walk together'), 'to walk together');
    });

    test('cuts a long line at a word', () {
      expect(
        previewLine(
          'The grace of the Lord Jesus Christ be with you',
          maxLength: 20,
        ),
        'The grace of the…',
      );
    });

    test('is null without text', () {
      expect(previewLine(null), isNull);
      expect(previewLine('  \n '), isNull);
    });
  });

  group('parseAlsoSungTo', () {
    test('reads each tune and its hymn number', () {
      expect(
        parseAlsoSungTo('Also sung to: Adeste Fideles (100), St. Denio (34)'),
        [
          (tune: 'Adeste Fideles', number: 100),
          (tune: 'St. Denio', number: 34),
        ],
      );
    });

    test('finds the line among other chorister notes', () {
      expect(parseAlsoSungTo('Sopranos lead.\nalso sung to: Toplady'), [
        (tune: 'Toplady', number: null),
      ]);
    });

    test('accepts a bare hymn number', () {
      expect(parseAlsoSungTo('Also sung to: 100'), [(tune: '', number: 100)]);
    });

    test('is empty when the notes say nothing about other tunes', () {
      expect(parseAlsoSungTo('Hold the fermata.'), isEmpty);
      expect(parseAlsoSungTo(null), isEmpty);
    });
  });
}
