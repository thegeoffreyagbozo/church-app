import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/labels.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_page.dart';
import '../../../core/widgets/missing_item.dart';
import '../../../core/widgets/opened_marker.dart';
import '../../../l10n/app_localizations.dart';
import '../../item_menu/domain/share_text.dart';
import '../../item_menu/presentation/item_menu.dart';
import '../data/readings_providers.dart';
import 'reading_part_view.dart';

/// A responsive reading, collection, creed or covenant (spec section 3.5).
class ReadingPage extends ConsumerWidget {
  const ReadingPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(readingProvider(id));
    return OpenedMarker(
      type: ItemType.reading,
      id: id,
      child: switch (reading) {
        AsyncData(value: final reading?) => _Reading(reading),
        AsyncData() || AsyncError() => const MissingItem(),
        _ => const Scaffold(),
      },
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading(this.reading);

  final ReadingDetail reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final together = reading.readTogether;
    return ItemPage(
      kicker: readingKicker(l10n, reading.kind),
      number: reading.number,
      title: reading.title,
      subtitle: reading.scriptureRef,
      actions: [
        ItemMenuButton(
          subject: MenuSubject(
            label: itemLabel(readingName(l10n, reading.number), reading.title),
            isHymn: false,
            isPublicDomain: reading.isPublicDomain,
            shareText: (church) =>
                readingShareText(l10n, reading, churchName: church),
          ),
        ),
      ],
      children: [
        if (together)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.palette.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 18, color: theme.palette.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.readTogether, style: theme.text.bodyStrong),
                ),
              ],
            ),
          ),
        for (final part in reading.parts)
          ReadingPartView(part, together: together),
      ],
    );
  }
}
