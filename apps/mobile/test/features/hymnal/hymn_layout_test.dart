import 'package:church_app/features/hymnal/domain/hymn_layout.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

const v1 = HymnText(type: HymnSectionType.verse, number: 1, lyrics: 'one');
const v2 = HymnText(type: HymnSectionType.verse, number: 2, lyrics: 'two');
const v3 = HymnText(type: HymnSectionType.verse, number: 3, lyrics: 'three');
const chorus = HymnText(type: HymnSectionType.chorus, lyrics: 'chorus');

void main() {
  group('withChorusAfterEachVerse', () {
    test('repeats a chorus printed once after the first verse', () {
      expect(withChorusAfterEachVerse([v1, chorus, v2, v3]), [
        v1,
        chorus,
        v2,
        chorus,
        v3,
        chorus,
      ]);
    });

    test('keeps a chorus printed first and adds it after each verse', () {
      expect(withChorusAfterEachVerse([chorus, v1, v2]), [
        chorus,
        v1,
        chorus,
        v2,
        chorus,
      ]);
    });

    test('leaves hymns without a chorus alone', () {
      expect(withChorusAfterEachVerse([v1, v2]), [v1, v2]);
    });

    test('leaves hymns that print several choruses alone', () {
      const other = HymnText(type: HymnSectionType.refrain, lyrics: 'other');
      expect(withChorusAfterEachVerse([v1, chorus, v2, other]), [
        v1,
        chorus,
        v2,
        other,
      ]);
    });
  });

  group('creditsLine', () {
    test('joins words and music, turning "; " into ", "', () {
      expect(
        creditsLine(
          'Edmond L. Budry; translated by Richard B. Hoyle',
          'Handel',
        ),
        'Edmond L. Budry, translated by Richard B. Hoyle · Handel',
      );
    });

    test('shows whichever credit is printed', () {
      expect(
        creditsLine(null, 'From Caldwell\'s Union Harmony, 1837'),
        'From Caldwell\'s Union Harmony, 1837',
      );
      expect(creditsLine(null, null), isNull);
    });
  });
}
