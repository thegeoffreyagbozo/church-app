import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/church_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/hymnal_theme.dart';
import 'core/theme/palette.dart';
import 'features/settings/domain/reading_settings.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'l10n/app_localizations.dart';

/// The app once the hymn book is open: themes from the church's colours and the
/// reader's settings, English strings, and the router.
class HymnalApp extends ConsumerWidget {
  const HymnalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(churchConfigProvider);
    final settings = ref.watch(readingSettingsProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(
        HymnalPalette.paper(primary: config.primary, accent: config.accent),
        legible: settings.legibleType,
      ),
      darkTheme: buildTheme(
        HymnalPalette.night(primary: config.primary, accent: config.accent),
        legible: settings.legibleType,
      ),
      themeMode: switch (settings.theme) {
        ReadingTheme.paper => ThemeMode.light,
        ReadingTheme.night => ThemeMode.dark,
        ReadingTheme.auto => ThemeMode.system,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Lists and buttons follow the phone's text size up to 2x; hymn and reading text
      // has its own scale on top (see reading_text_scale.dart).
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 2, child: child!),
    );
  }
}
