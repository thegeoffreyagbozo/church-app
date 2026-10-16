import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// The palette and text styles of the current theme, reachable from any widget.
@immutable
class HymnalTheme extends ThemeExtension<HymnalTheme> {
  const HymnalTheme(this.palette, this.text);

  final HymnalPalette palette;
  final HymnalType text;

  static HymnalTheme of(BuildContext context) =>
      Theme.of(context).extension<HymnalTheme>()!;

  @override
  HymnalTheme copyWith({HymnalPalette? palette, HymnalType? text}) =>
      HymnalTheme(palette ?? this.palette, text ?? this.text);

  // Themes switch instantly; there is nothing to interpolate.
  @override
  HymnalTheme lerp(HymnalTheme? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Material theme for [palette], so built-in widgets (switches, sliders, sheets) match.
ThemeData buildTheme(HymnalPalette palette, {bool legible = false}) {
  final text = HymnalType(palette, legible: legible);
  final scheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    secondary: palette.accent,
    onSecondary: palette.background,
    error: palette.accent,
    onError: palette.background,
    surface: palette.background,
    onSurface: palette.ink,
    onSurfaceVariant: palette.muted,
    surfaceContainerHighest: palette.surface,
    outline: palette.rule,
    outlineVariant: palette.rule,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    fontFamily: legible ? 'AtkinsonHyperlegible' : 'Inter',
    dividerTheme: DividerThemeData(color: palette.rule, thickness: 1, space: 1),
    // The Android tab bar: a solid bar with the selected tab in the brand colour.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: palette.primary.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.primary
              : palette.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? text.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.primary,
              )
            : text.caption.copyWith(fontSize: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: text.body.copyWith(color: palette.background),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: [HymnalTheme(palette, text)],
  );
}
