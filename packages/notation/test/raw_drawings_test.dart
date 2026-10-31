import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/raw_drawings.dart';
import 'package:notation/testing.dart';

void main() {
  late List<String> rendered;
  late RawDrawings drawings;

  setUp(() {
    rendered = [];
    drawings = RawDrawings((xml, options) {
      rendered.add(options);
      return ['<svg>${xml.length}</svg>'];
    }, capacity: 2);
  });

  test('the same verse at the same size runs Verovio once', () {
    drawings.draw(oldHundredth(), 1, 'o');
    drawings.draw(oldHundredth(), 1, 'o');
    expect(rendered, hasLength(1));
  });

  test('another verse or size runs it again', () {
    drawings.draw(oldHundredth(), 1, 'o');
    drawings.draw(oldHundredth(), 2, 'o');
    drawings.draw(oldHundredth(), 1, 'p');
    expect(rendered, hasLength(3));
  });

  test('keeps only the most recently used drawings', () {
    drawings.draw(oldHundredth(), 1, 'o');
    drawings.draw(oldHundredth(), 2, 'o');
    drawings.draw(oldHundredth(), 1, 'o'); // 1 is now the most recent
    drawings.draw(oldHundredth(), 3, 'o'); // drops 2
    drawings.draw(oldHundredth(), 2, 'o');
    expect(rendered, hasLength(4));
  });
}
