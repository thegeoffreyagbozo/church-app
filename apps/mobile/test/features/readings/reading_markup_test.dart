import 'package:church_app/features/readings/domain/reading_markup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads bold runs', () {
    final lines = parseReadingMarkup(
      'enter into **covenant** with one another',
    );

    expect(lines.single.runs, const [
      MarkupRun('enter into '),
      MarkupRun('covenant', bold: true),
      MarkupRun(' with one another'),
    ]);
  });

  test('reads bullets and skips blank lines', () {
    final lines = parseReadingMarkup(
      '**We engage:**\n\n- to **walk** together',
    );

    expect(lines, hasLength(2));
    expect(lines.first.bullet, isFalse);
    expect(lines.last.bullet, isTrue);
    expect(lines.last.text, 'to walk together');
  });

  test('shows an unclosed ** as typed', () {
    final lines = parseReadingMarkup('a **broken line');

    expect(lines.single.runs, const [MarkupRun('a **broken line')]);
  });

  test('plain text for sharing uses bullet marks', () {
    expect(
      plainReadingText('**We engage:**\n- to **walk** together'),
      'We engage:\n• to walk together',
    );
  });
}
