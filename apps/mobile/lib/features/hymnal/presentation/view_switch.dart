import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared/shared.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_controller.dart';

/// The Words | Music switch at the top of a hymn page (spec section 3.3).
class ViewSwitch extends ConsumerWidget {
  const ViewSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = HymnalTheme.of(context).palette;
    final view = ref.watch(readingSettingsProvider.select((s) => s.hymnView));
    final controller = ref.read(readingSettingsProvider.notifier);
    Widget segment(HymnViewMode mode, IconData icon, String label) {
      final selected = view == mode;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => controller.setHymnView(mode),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? palette.surface : null,
                borderRadius: BorderRadius.circular(24),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? palette.primary : palette.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.tint,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(HymnViewMode.ordinary, LucideIcons.listMusic, l10n.wordsView),
          segment(HymnViewMode.chorister, LucideIcons.music, l10n.musicView),
        ],
      ),
    );
  }
}
