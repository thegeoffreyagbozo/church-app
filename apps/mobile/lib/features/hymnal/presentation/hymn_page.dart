import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../../core/labels.dart';
import '../../../core/widgets/item_page.dart';
import '../../../core/widgets/missing_item.dart';
import '../../../core/widgets/opened_marker.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/hymnal_providers.dart';
import '../domain/hymn_layout.dart';
import 'hymn_text_block.dart';
import 'music_card.dart';
import 'view_switch.dart';

/// One hymn: every verse on one page, the chorus after each (spec section 3.3). The
/// `···` menu joins in Task 16.
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
    final music =
        ref.watch(readingSettingsProvider.select((s) => s.hymnView)) ==
        HymnViewMode.chorister;
    return ItemPage(
      kicker: hymnKicker(l10n, hymn.section),
      number: hymn.number,
      title: hymn.title,
      subtitle: creditsLine(hymn.author, hymn.composer),
      actions: const [ViewSwitch()],
      children: [
        if (music) MusicCard(hymn),
        for (final text in withChorusAfterEachVerse(hymn.texts))
          HymnTextBlock(text),
      ],
    );
  }
}
