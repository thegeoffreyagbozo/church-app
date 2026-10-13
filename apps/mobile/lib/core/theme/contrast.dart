import 'package:flutter/painting.dart';

/// The WCAG contrast ratio of two colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// [color], darkened or lightened just enough to reach [ratio] against [background]
/// (WCAG AA for text is 4.5). Keeps its hue, so a church's colours stay recognisable.
Color ensureContrast(Color color, Color background, {double ratio = 4.5}) {
  if (contrastRatio(color, background) >= ratio) return color;
  final hsl = HSLColor.fromColor(color);
  final darken = background.computeLuminance() > 0.5;
  for (var step = 1; step <= 100; step++) {
    final lightness = (hsl.lightness + (darken ? -step : step) / 100).clamp(
      0.0,
      1.0,
    );
    final candidate = hsl.withLightness(lightness).toColor();
    if (contrastRatio(candidate, background) >= ratio) return candidate;
  }
  return darken ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

/// [color] with its lightness set to [lightness] and its saturation capped at
/// [maxSaturation].
Color tone(Color color, double lightness, {double maxSaturation = 1}) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(lightness)
      .withSaturation(hsl.saturation.clamp(0, maxSaturation))
      .toColor();
}
