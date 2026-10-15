import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/content_providers.dart';
import '../../../core/platform/platform_services.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/page_width.dart';
import '../../../l10n/app_localizations.dart';
import 'reading_settings_sheet.dart';
import 'settings_controller.dart';

/// When the bundled hymn book was built.
final contentBuiltProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(catalogProvider).builtAt(),
);

/// The Settings tab (spec section 3.7).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final settings = ref.watch(readingSettingsProvider);
    final controller = ref.read(readingSettingsProvider.notifier);
    final church = ref.watch(churchProvider).value;
    final built = ref.watch(contentBuiltProvider).value;
    final version = ref.watch(appVersionProvider).value;
    Widget toggle(
      String title,
      String hint,
      bool value,
      ValueChanged<bool> set,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.text.body),
      subtitle: Text(hint, style: theme.text.caption),
      value: value,
      onChanged: set,
    );
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          sidePadding(context),
          16,
          sidePadding(context),
          110 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.tabSettings, style: theme.text.screenTitle),
          ),
          _Heading(l10n.settingsReading),
          const TextSizeControl(),
          const SizedBox(height: 8),
          const ThemeControl(),
          const SizedBox(height: 8),
          toggle(
            l10n.legibleType,
            l10n.legibleTypeHint,
            settings.legibleType,
            controller.setLegibleType,
          ),
          toggle(
            l10n.keepScreenOn,
            l10n.keepScreenOnHint,
            settings.keepScreenOn,
            controller.setKeepScreenOn,
          ),
          toggle(
            l10n.numberRow,
            l10n.numberRowHint,
            settings.digitRow,
            controller.setDigitRow,
          ),
          _Heading(l10n.settingsAbout),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.appVersion, style: theme.text.body),
            trailing: Text(version ?? '', style: theme.text.caption),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.contentBuilt, style: theme.text.body),
            trailing: Text(
              built == null ? '' : DateFormat.yMMMd().format(built.toLocal()),
              style: theme.text.caption,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.licences, style: theme.text.body),
            onTap: () => showLicensePage(
              context: context,
              applicationName: church?.name ?? l10n.appTitle,
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: HymnalTheme.of(context).text.listLabel,
    ),
  );
}
