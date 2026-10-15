import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../core/theme/reading_text_scale.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reading_settings.dart';
import 'settings_controller.dart';

/// The "Text size and theme" sheet of the `···` menu.
Future<void> showReadingSettingsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context).menuTextAndTheme,
                  style: HymnalTheme.of(context).text.listTitle,
                ),
                const SizedBox(height: 12),
                const TextSizeControl(),
                const SizedBox(height: 16),
                const ThemeControl(),
              ],
            ),
          ),
        ),
      ),
    );

/// A preview line at the chosen size and the slider (0.5 to 2.0, in steps of 10%).
class TextSizeControl extends ConsumerWidget {
  const TextSizeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final scale = ref.watch(readingSettingsProvider.select((s) => s.textScale));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.textSize, style: theme.text.bodyStrong),
        const SizedBox(height: 8),
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: readingTextScaler(
              MediaQuery.textScalerOf(context),
              scale,
            ),
          ),
          child: Text(
            l10n.textSizeSample,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.text.verse,
          ),
        ),
        Slider(
          value: scale,
          min: ReadingSettings.minTextScale,
          max: ReadingSettings.maxTextScale,
          divisions: 15,
          label: '${(scale * 100).round()}%',
          semanticFormatterCallback: (v) => '${(v * 100).round()}%',
          onChanged: ref.read(readingSettingsProvider.notifier).setTextScale,
        ),
      ],
    );
  }
}

/// Paper, Night or Auto.
class ThemeControl extends ConsumerWidget {
  const ThemeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(readingSettingsProvider.select((s) => s.theme));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.theme, style: HymnalTheme.of(context).text.bodyStrong),
        const SizedBox(height: 8),
        SegmentedButton<ReadingTheme>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ReadingTheme.paper,
              label: Text(l10n.themePaper),
            ),
            ButtonSegment(
              value: ReadingTheme.night,
              label: Text(l10n.themeNight),
            ),
            ButtonSegment(
              value: ReadingTheme.auto,
              label: Text(l10n.themeAuto),
            ),
          ],
          selected: {theme},
          onSelectionChanged: (choice) => ref
              .read(readingSettingsProvider.notifier)
              .setTheme(choice.single),
        ),
      ],
    );
  }
}
