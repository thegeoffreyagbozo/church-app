import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/hymnal_theme.dart';

/// The three tabs, with each platform's own tab bar docked at the bottom (ADR 0010):
/// Material 3 on Android, the iOS tab bar on iPhone. Hidden while the keyboard is up.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: shell,
      bottomNavigationBar: keyboard ? null : _TabBar(shell: shell),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = HymnalTheme.of(context).palette;
    final tabs = [
      (LucideIcons.bookOpen, l10n.tabHymns),
      (LucideIcons.list, l10n.tabReadings),
      (LucideIcons.settings, l10n.tabSettings),
    ];
    final edge = Border(top: BorderSide(color: palette.rule));
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoTabBar(
        currentIndex: shell.currentIndex,
        onTap: _select,
        activeColor: palette.primary,
        inactiveColor: palette.muted,
        backgroundColor: palette.surface,
        border: edge,
        items: [
          for (final (icon, label) in tabs)
            BottomNavigationBarItem(icon: Icon(icon), label: label),
        ],
      );
    }
    // Colours come from the theme's navigationBarTheme (buildTheme).
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(border: edge),
      child: NavigationBar(
        height: 64,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, label) in tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
