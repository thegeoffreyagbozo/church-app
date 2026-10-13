import 'package:church_app/core/theme/reading_text_scale.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readingTextScaler', () {
    test('multiplies the phone text size by the reader size', () {
      final scaler = readingTextScaler(const TextScaler.linear(1.2), 1.5);

      expect(scaler.scale(20), closeTo(36, 0.01));
    });

    test('caps the result at 2.5 times', () {
      final scaler = readingTextScaler(const TextScaler.linear(2), 2);

      expect(scaler.scale(20), 50);
    });
  });
}
