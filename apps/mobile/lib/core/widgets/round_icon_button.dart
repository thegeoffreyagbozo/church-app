import 'package:flutter/material.dart';

import '../theme/hymnal_theme.dart';

/// A round, tinted icon button with a 48 dp touch target and a spoken name.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;

  /// Read by screen readers and shown on long press.
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = HymnalTheme.of(context).palette;
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(48),
        backgroundColor: selected ? palette.primary : palette.tint,
        foregroundColor: selected ? palette.onPrimary : palette.primary,
      ),
    );
  }
}
