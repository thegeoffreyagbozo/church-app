import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../../core/labels.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_page.dart';
import '../../../core/widgets/missing_item.dart';
import '../../../core/widgets/opened_marker.dart';
import '../../../l10n/app_localizations.dart';
import '../../item_menu/domain/share_text.dart';
import '../../item_menu/presentation/item_menu.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/hymnal_providers.dart';
import '../domain/hymn_layout.dart';
import 'hymn_text_block.dart';
import 'music_card.dart';
import 'music_pages.dart';
import 'view_switch.dart';

/// One hymn: every verse on one page, the chorus after each (spec section 3.3).
class HymnPage extends ConsumerWidget {
  const HymnPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hymn = ref.watch(hymnProvider(id));
    return OpenedMarker(
      type: ItemType.hymn,
      id: id,
      child: switch (hymn) {
        AsyncData(value: final hymn?) => _Hymn(hymn),
        AsyncData() || AsyncError() => const MissingItem(),
        _ => const Scaffold(),
      },
    );
  }
}

class _Hymn extends ConsumerWidget {
  const _Hymn(this.hymn);

  final HymnDetail hymn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final music =
        ref.watch(readingSettingsProvider.select((s) => s.hymnView)) ==
        HymnViewMode.chorister;
    final showMusic = music && hymn.music.isNotEmpty;
    final label = itemLabel(
      hymnName(l10n, hymn.section, hymn.number),
      hymn.title,
    );
    return ItemPage(
      kicker: hymnKicker(l10n, hymn.section, group: hymn.group),
      number: hymn.number,
      title: hymn.title,
      subtitle: creditsLine(hymn.author, hymn.composer),
      resizable: !showMusic,
      actions: [
        const ViewSwitch(),
        const SizedBox(width: 6),
        ItemMenuButton(
          subject: MenuSubject(
            label: label,
            isHymn: true,
            isPublicDomain: hymn.isPublicDomain,
            shareText: (church) =>
                hymnShareText(l10n, hymn, churchName: church),
          ),
        ),
      ],
      children: [
        if (music) MusicCard(hymn),
        if (showMusic) ...[
          MusicPages(hymn),
          Text(
            l10n.tapToZoom,
            textAlign: TextAlign.center,
            style: theme.text.caption,
          ),
        ] else
          for (final text in withChorusAfterEachVerse(hymn.texts))
            HymnTextBlock(text),
      ],
    );
  }
}
