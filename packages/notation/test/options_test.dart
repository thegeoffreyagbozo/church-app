import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/options.dart';

Map<String, Object?> _decode(String json) => jsonDecode(json) as Map<String, Object?>;

void main() {
  test('the page is as wide as the screen at the given scale', () {
    final options = _decode(verovioOptions(width: 400, scale: 40));

    expect(options['scale'], 40);
    expect(options['pageWidth'], 1000);
    expect(options['font'], 'Leland');
    expect(options['breaks'], 'auto');
    expect(options['adjustPageHeight'], true);
    expect(options['svgAdditionalAttribute'], ['staff@n', 'layer@n']);
  });

  test('an extreme scale is clamped', () {
    expect(_decode(verovioOptions(width: 400, scale: 1))['scale'], minScale);
    expect(_decode(verovioOptions(width: 400, scale: 999))['scale'], maxScale);
  });

  test('a tiny or huge width still gives Verovio a page it accepts', () {
    expect(_decode(verovioOptions(width: 1, scale: 40))['pageWidth'], 500);
    expect(_decode(verovioOptions(width: 100000, scale: 20))['pageWidth'], 60000);
  });
}
