import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Values from the church settings file (ADR 0007), passed to the build with
/// `--dart-define-from-file`. Only public values belong there.
class ChurchConfig {
  const ChurchConfig({
    this.primary = defaultPrimary,
    this.accent = defaultAccent,
    this.tagline,
  });

  /// Reads `BRAND_PRIMARY`, `BRAND_ACCENT` and `CHURCH_TAGLINE`.
  factory ChurchConfig.fromEnvironment() => ChurchConfig(
    primary:
        parseHexColor(const String.fromEnvironment('BRAND_PRIMARY')) ??
        defaultPrimary,
    accent:
        parseHexColor(const String.fromEnvironment('BRAND_ACCENT')) ??
        defaultAccent,
    tagline: switch (const String.fromEnvironment('CHURCH_TAGLINE').trim()) {
      '' => null,
      final tagline => tagline,
    },
  );

  /// Neutral ink blue and oxblood, used until a church sets its own colours.
  static const defaultPrimary = Color(0xFF24426B);
  static const defaultAccent = Color(0xFF8E2C3A);

  /// Numbers, buttons and the reading band.
  final Color primary;

  /// Kickers and verse numbers.
  final Color accent;

  /// A line under the church name on Home, such as a motto.
  final String? tagline;
}

/// Parses "#RRGGBB" or "RRGGBB"; null for anything else.
Color? parseHexColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}

final churchConfigProvider = Provider<ChurchConfig>(
  (ref) => ChurchConfig.fromEnvironment(),
);
