import 'package:church_app/core/config/church_config.dart';
import 'package:church_app/core/theme/contrast.dart';
import 'package:church_app/core/theme/palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHexColor', () {
    test('reads #RRGGBB and RRGGBB', () {
      expect(parseHexColor('#1C3F6E'), const Color(0xFF1C3F6E));
      expect(parseHexColor('a3243b'), const Color(0xFFA3243B));
    });

    test('is null for anything else', () {
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor('navy'), isNull);
    });
  });

  test('without a settings file the app uses the neutral colours', () {
    final config = ChurchConfig.fromEnvironment();

    expect(config.primary, ChurchConfig.defaultPrimary);
    expect(config.accent, ChurchConfig.defaultAccent);
  });

  group('contrast', () {
    test('measures black on white as 21', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('darkens a pale colour until it reads on paper', () {
      const paper = Color(0xFFFBF8F1);
      final fixed = ensureContrast(const Color(0xFFFFD54F), paper);

      expect(contrastRatio(fixed, paper), greaterThanOrEqualTo(4.5));
      expect(
        HSLColor.fromColor(fixed).hue,
        closeTo(HSLColor.fromColor(const Color(0xFFFFD54F)).hue, 1),
      );
    });
  });

  // Brand pairs a church might choose, including hard ones.
  const brands = {
    'neutral default': (
      ChurchConfig.defaultPrimary,
      ChurchConfig.defaultAccent,
    ),
    'navy and crimson': (Color(0xFF0B2E59), Color(0xFFB0102B)),
    'gold and green': (Color(0xFFFFC107), Color(0xFF8BC34A)),
    'white and black': (Color(0xFFFFFFFF), Color(0xFF000000)),
    'purple and orange': (Color(0xFF6A1B9A), Color(0xFFFF6F00)),
  };

  for (final MapEntry(key: name, value: (primary, accent)) in brands.entries) {
    for (final palette in [
      HymnalPalette.paper(primary: primary, accent: accent),
      HymnalPalette.night(primary: primary, accent: accent),
    ]) {
      test(
        'every text colour meets WCAG AA: $name, ${palette.brightness.name}',
        () {
          for (final (role, colour) in [
            ('ink', palette.ink),
            ('muted', palette.muted),
            ('primary', palette.primary),
            ('accent', palette.accent),
          ]) {
            expect(
              contrastRatio(colour, palette.background),
              greaterThanOrEqualTo(4.5),
              reason: '$role on background',
            );
          }
          final band = Color.alphaBlend(palette.band, palette.background);
          expect(contrastRatio(palette.ink, band), greaterThanOrEqualTo(4.5));
          expect(
            contrastRatio(palette.onPrimary, palette.primary),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }
  }
}
