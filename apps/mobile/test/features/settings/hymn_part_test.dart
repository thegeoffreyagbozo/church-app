import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  test('the part is saved and read back, All by default', () {
    const settings = ReadingSettings(hymnPart: HymnPart.alto);
    expect(ReadingSettings.fromMap(settings.toMap()).hymnPart, HymnPart.alto);
    expect(ReadingSettings.fromMap(const {}).hymnPart, HymnPart.all);
    expect(
      ReadingSettings.fromMap(const {'hymn_part': 'nonsense'}).hymnPart,
      HymnPart.all,
    );
  });

  test('each part names the voice the drawing keeps in full ink', () {
    expect(HymnPart.all.notationPart, isNull);
    expect(HymnPart.tenor.notationPart, Part.tenor);
  });

  test('the drawing grows with the text size', () {
    expect(notationScale(1.0), defaultScale);
    expect(notationScale(1.5), 60);
    expect(notationScale(0.5), 20);
  });
}
