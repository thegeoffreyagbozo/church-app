import 'package:flutter/material.dart';

import 'contrast.dart';

/// The colours of one reading theme, derived from the church's two brand colours so any
/// church's app looks right (spec section 2). Every text colour meets WCAG AA.
@immutable
class HymnalPalette {
  const HymnalPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.band,
    required this.tint,
    required this.glass,
    required this.glassBorder,
    required this.scrim,
  });

  /// Warm paper with the brand colours as ink.
  factory HymnalPalette.paper({required Color primary, required Color accent}) {
    const background = Color(0xFFFBF8F1);
    final brand = ensureContrast(primary, background);
    return HymnalPalette(
      brightness: Brightness.light,
      background: background,
      surface: const Color(0xFFFFFFFF),
      ink: const Color(0xFF1F1A15),
      muted: ensureContrast(const Color(0xFF857A6D), background),
      rule: const Color(0xFFEADFCD),
      primary: brand,
      onPrimary: ensureContrast(const Color(0xFFFFFFFF), brand),
      accent: ensureContrast(accent, background),
      band: brand.withValues(alpha: 0.065),
      tint: brand.withValues(alpha: 0.08),
      glass: background.withValues(alpha: 0.72),
      glassBorder: const Color(0xBFFFFFFF),
      scrim: const Color(0x2E1F1A15),
    );
  }

  /// A deep background in the primary colour's hue, for dim churches.
  factory HymnalPalette.night({required Color primary, required Color accent}) {
    final background = tone(primary, 0.09, maxSaturation: 0.6);
    final brand = ensureContrast(
      tone(primary, 0.77, maxSaturation: 0.72),
      background,
      ratio: 7,
    );
    return HymnalPalette(
      brightness: Brightness.dark,
      background: background,
      surface: tone(primary, 0.14, maxSaturation: 0.45),
      ink: const Color(0xFFECE5D8),
      muted: ensureContrast(const Color(0xFF98A2B6), background),
      rule: tone(primary, 0.22, maxSaturation: 0.35),
      primary: brand,
      onPrimary: background,
      accent: ensureContrast(
        tone(accent, 0.71, maxSaturation: 0.83),
        background,
      ),
      band: brand.withValues(alpha: 0.12),
      tint: const Color(0x14FFFFFF),
      glass: tone(primary, 0.12, maxSaturation: 0.5).withValues(alpha: 0.78),
      glassBorder: const Color(0x33FFFFFF),
      scrim: const Color(0x66000000),
    );
  }

  final Brightness brightness;
  final Color background;

  /// Cards, the search bar and solid stand-ins for glass.
  final Color surface;
  final Color ink;

  /// Credits, first lines and hints.
  final Color muted;
  final Color rule;

  /// Numbers, buttons and links.
  final Color primary;
  final Color onPrimary;

  /// Kickers and verse numbers.
  final Color accent;

  /// Behind the bold voice of a responsive reading.
  final Color band;

  /// Behind round buttons and switches.
  final Color tint;
  final Color glass;
  final Color glassBorder;
  final Color scrim;
}
