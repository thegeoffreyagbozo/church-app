import 'dart:typed_data';

import 'package:content_db/content_db.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('reads the size from a PNG header', () {
    final size = pngSize(fakePng(1200, 900))!;
    expect((size.width, size.height), (1200, 900));
  });

  test('anything else has no size', () {
    expect(pngSize(Uint8List.fromList([1, 2, 3])), isNull);
    expect(pngSize(Uint8List(40)), isNull);
  });
}
