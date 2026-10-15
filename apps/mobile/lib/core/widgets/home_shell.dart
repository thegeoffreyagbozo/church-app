import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/hymnal_theme.dart';
import 'glass_surface.dart';

/// The three tabs with a floating glass tab bar, hidden while the keyboard is up.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = HymnalTheme.of(context).palette;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: keyboard
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(30),
                child: NavigationBar(
                  height: 64,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: palette.tint,
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (i) => shell.goBranch(
                    i,
                    initialLocation: i == shell.currentIndex,
                  ),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(LucideIcons.bookOpen),
                      label: l10n.tabHymns,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.list),
                      label: l10n.tabReadings,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.settings),
                      label: l10n.tabSettings,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
