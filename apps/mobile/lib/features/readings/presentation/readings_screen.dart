import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../../core/labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_row.dart';
import '../../../core/widgets/page_width.dart';
import '../../../l10n/app_localizations.dart';
import '../data/readings_providers.dart';

/// The Readings tab: cards for the covenant and creed, then the numbered readings
/// (spec section 3.4).
class ReadingsScreen extends ConsumerWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final readings = ref.watch(readingsProvider).value ?? const [];
    bool isCard(ReadingListItem r) =>
        r.kind == ReadingKind.covenant || r.kind == ReadingKind.creed;
    final cards = readings.where(isCard).toList();
    final list = readings.where((r) => !isCard(r)).toList();
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
            child: Text(l10n.tabReadings, style: theme.text.screenTitle),
          ),
          const SizedBox(height: 16),
          for (final reading in cards) _ReadingCard(reading),
          for (final reading in list)
            ItemRow(
              number: reading.number,
              title: Text(reading.title),
              subtitle: switch (reading.scriptureRef ?? reading.preview) {
                final line? => Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                null => null,
              },
              onTap: () => context.push(readingPath(reading.id)),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard(this.reading);

  final ReadingListItem reading;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.palette.rule),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(readingPath(reading.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  readingKicker(
                    AppLocalizations.of(context),
                    reading.kind,
                  ).toUpperCase(),
                  style: theme.text.label,
                ),
                const SizedBox(height: 4),
                Text(reading.title, style: theme.text.listTitle),
                if (reading.preview != null)
                  Text(
                    reading.preview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.listSubtitle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
