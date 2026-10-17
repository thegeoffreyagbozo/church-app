import 'package:church_app/features/hymnal/presentation/music_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [m] applied to one RGBA pixel (0 to 255 per channel), as a colour filter does.
List<double> apply(List<double> m, List<double> rgba) => [
  for (var row = 0; row < 4; row++)
    m[row * 5] * rgba[0] +
        m[row * 5 + 1] * rgba[1] +
        m[row * 5 + 2] * rgba[2] +
        m[row * 5 + 3] * rgba[3] +
        m[row * 5 + 4],
];

void main() {
  test('ink is drawn in the theme colour and paper becomes clear', () {
    final m = inkMatrix(const Color(0xFF203040));
    final black = apply(m, [0, 0, 0, 255]);
    final white = apply(m, [255, 255, 255, 255]);
    expect(black.map((v) => v.round()), [0x20, 0x30, 0x40, 255]);
    expect(white[3], closeTo(0, 0.5));
  });
}
