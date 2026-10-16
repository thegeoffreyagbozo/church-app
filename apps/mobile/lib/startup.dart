import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'app.dart';
import 'core/config/church_config.dart';
import 'core/database/bootstrap.dart';
import 'core/database/content_providers.dart';
import 'core/theme/hymnal_theme.dart';
import 'core/theme/palette.dart';
import 'features/settings/domain/reading_settings.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'l10n/app_localizations.dart';

/// Opens the hymn book, then starts the app with it. The native splash covers the wait
/// ([onReady]); a message with Retry follows if opening fails (spec section 8).
class StartupApp extends StatefulWidget {
  const StartupApp({
    super.key,
    this.open = openBundledContent,
    this.loadLogo = loadChurchLogo,
    this.onReady,
    this.overrides = const [],
  });

  final Future<ContentDatabase> Function() open;

  /// Loads the church's logo for Home ([churchLogoProvider]).
  final Future<ImageProvider?> Function() loadLogo;

  /// Called once, when the hymn book is open or has failed to open. `main` holds the
  /// first frame until then, so the native splash leads straight to Home.
  final VoidCallback? onReady;

  /// Extra provider overrides, for tests.
  final List<Override> overrides;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<(ContentDatabase, ReadingSettings, ImageProvider?)> _ready =
      _load();
  var _released = false;

  Future<(ContentDatabase, ReadingSettings, ImageProvider?)> _load() async {
    try {
      final logo = widget.loadLogo();
      final db = await widget.open();
      final settings = ReadingSettings.fromMap(await UserData(db).settings());
      return (db, settings, await logo);
    } finally {
      if (!_released) {
        _released = true;
        widget.onReady?.call();
      }
    }
  }

  void _retry() {
    setState(() {
      _ready = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.data case (final db, final settings, final logo)) {
          return ProviderScope(
            retry: (_, _) => null,
            overrides: [
              contentDatabaseProvider.overrideWithValue(db),
              initialSettingsProvider.overrideWithValue(settings),
              churchLogoProvider.overrideWithValue(logo),
              ...widget.overrides,
            ],
            child: const HymnalApp(),
          );
        }
        final config = ChurchConfig.fromEnvironment();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(
            HymnalPalette.paper(primary: config.primary, accent: config.accent),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: snapshot.hasError
              ? _StartupError(error: snapshot.error!, onRetry: _retry)
              : const Scaffold(),
        );
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is NotEnoughSpaceException
                      ? l10n.startupNoSpace
                      : l10n.startupFailed,
                  textAlign: TextAlign.center,
                  style: theme.text.body,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
