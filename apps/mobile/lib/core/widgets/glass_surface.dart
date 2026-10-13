import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/platform_services.dart';
import '../theme/hymnal_theme.dart';

/// Frosted glass over the page (Flutter's blur). Solid on low-memory phones and when
/// the phone asks for high contrast, so it never costs speed or legibility.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HymnalTheme.of(context).palette;
    final solid =
        MediaQuery.highContrastOf(context) ||
        (ref.watch(solidSurfacesProvider).value ?? true);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: solid ? palette.surface : palette.glass,
        borderRadius: borderRadius,
        border: border ? Border.all(color: palette.glassBorder) : null,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x290A1932),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (solid) return surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: surface,
      ),
    );
  }
}
