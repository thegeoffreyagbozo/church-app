import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/database/content_providers.dart';
import '../../../core/platform/platform_services.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/glass_menu.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/reading_settings_sheet.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/report.dart';

/// What the `···` menu acts on.
class MenuSubject {
  const MenuSubject({
    required this.label,
    required this.isHymn,
    required this.isPublicDomain,
    required this.shareText,
  });

  /// "Hymn 41 · How Firm a Foundation".
  final String label;
  final bool isHymn;
  final bool isPublicDomain;

  /// Builds the shared text, given the church's name.
  final String Function(String churchName) shareText;
}

/// The `···` button of hymn and reading pages (spec section 3.6).
class ItemMenuButton extends ConsumerStatefulWidget {
  const ItemMenuButton({super.key, required this.subject});

  final MenuSubject subject;

  @override
  ConsumerState<ItemMenuButton> createState() => _ItemMenuButtonState();
}

class _ItemMenuButtonState extends ConsumerState<ItemMenuButton> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      key: _key,
      icon: LucideIcons.ellipsis,
      label: AppLocalizations.of(context).more,
      onPressed: () => showGlassMenu(
        context,
        anchorKey: _key,
        builder: (_) =>
            _ItemMenu(subject: widget.subject, pageContext: context),
      ),
    );
  }
}

class _ItemMenu extends ConsumerWidget {
  const _ItemMenu({required this.subject, required this.pageContext});

  final MenuSubject subject;

  /// The page under the menu, which outlives it (for the sheet and messages).
  final BuildContext pageContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final church = ref.watch(churchProvider).value;
    final target = ReportTarget.of(church);
    final keepOn = ref.watch(
      readingSettingsProvider.select((s) => s.keepScreenOn),
    );
    void close() => Navigator.of(context).pop();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuRow(
          icon: LucideIcons.type,
          title: l10n.menuTextAndTheme,
          onTap: () {
            close();
            showReadingSettingsSheet(pageContext);
          },
        ),
        _MenuRow(
          icon: LucideIcons.sun,
          title: l10n.menuKeepScreenOn,
          trailing: Switch(
            value: keepOn,
            onChanged: ref
                .read(readingSettingsProvider.notifier)
                .setKeepScreenOn,
          ),
          onTap: () => ref
              .read(readingSettingsProvider.notifier)
              .setKeepScreenOn(!keepOn),
        ),
        _MenuRow(
          icon: LucideIcons.share2,
          title: subject.isHymn ? l10n.menuShareHymn : l10n.menuShareReading,
          subtitle: subject.isPublicDomain
              ? l10n.menuShareWords
              : l10n.menuShareTitle,
          onTap: () {
            final sharing = ref.read(sharingProvider);
            close();
            sharing.shareText(
              subject.shareText(church?.name ?? l10n.appTitle),
              subject: subject.label,
            );
          },
        ),
        if (target != null)
          _MenuRow(
            icon: LucideIcons.flag,
            title: l10n.menuReport,
            subtitle: l10n.menuReportHint,
            onTap: () {
              final launcher = ref.read(launcherProvider);
              close();
              reportMistake(
                pageContext,
                launcher,
                target,
                subject.label,
                church!.name,
              );
            },
          ),
      ],
    );
  }
}

/// Opens WhatsApp with the message, else email, else copies it and says so.
Future<void> reportMistake(
  BuildContext context,
  Launcher launcher,
  ReportTarget target,
  String label,
  String churchName,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final message = l10n.reportMessage(label);
  for (final uri in [
    target.whatsappUri(message),
    target.emailUri(l10n.reportSubject(label), message),
  ]) {
    if (uri != null &&
        await launcher.canOpen(uri) &&
        await launcher.open(uri)) {
      return;
    }
  }
  await Clipboard.setData(ClipboardData(text: message));
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.reportCopied(churchName))),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.palette.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.text.body),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.text.caption),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
