import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

void main() {
  bool pd(List<String> credits, {String? copyright}) =>
      isPublicDomain(credits, currentYear: 2026, copyright: copyright);

  test('everyone credited died over 70 years ago: public domain', () {
    expect(
      pd([
        'Thomas Ken, 1637-1711',
        'Louis Bourgeois, c. 1510-c. 1561, in the Genevan Psalter, 1551',
      ]),
      isTrue,
    );
  });

  test('an open-ended date (still living when printed) keeps it protected', () {
    expect(
      pd(['Thomas Hastings, 1784-1872', 'John W. Peterson, 1921-']),
      isFalse,
    );
  });

  test('protection lasts 70 full years after the year of death', () {
    expect(pd(['A Writer, 1880-1955']), isTrue);
    expect(pd(['A Writer, 1880-1956']), isFalse);
  });

  test('traditional texts are public domain', () {
    expect(pd(['Traditional']), isTrue);
  });

  test('credits without dates cannot be confirmed', () {
    expect(pd(['Edmond L. Budry', 'George Frederick Handel']), isFalse);
  });

  test('an anonymous source counts from its publication year', () {
    expect(pd(["From Caldwell's Union Harmony, 1837"]), isTrue);
  });

  test('no credits at all cannot be confirmed', () {
    expect(pd([]), isFalse);
  });

  test('a Copyright label overrides the printed dates', () {
    expect(pd([], copyright: 'public domain'), isTrue);
    expect(
      pd(['Thomas Ken, 1637-1711'], copyright: '1968 Stainer & Bell'),
      isFalse,
    );
  });
}
