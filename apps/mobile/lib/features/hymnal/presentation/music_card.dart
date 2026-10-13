import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../l10n/app_localizations.dart';

/// The Music view's card: only what the book prints (spec section 3.3).
class MusicCard extends StatelessWidget {
  const MusicCard(this.hymn, {super.key});

  final HymnDetail hymn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final rows = [
      if (hymn.tuneName != null) (l10n.tune, hymn.tuneName!),
      if (hymn.composer != null) (l10n.tuneSource, hymn.composer!),
      if (hymn.meter != null) (l10n.meter, hymn.meter!),
      if (hymn.musicKey != null) (l10n.musicKey, hymn.musicKey!),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.palette.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.musicCard.toUpperCase(), style: theme.text.label),
          const SizedBox(height: 6),
          if (rows.isEmpty && hymn.alsoSungTo.isEmpty)
            Text(l10n.noMusicDetails, style: theme.text.caption),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: theme.text.caption)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: theme.text.bodyStrong,
                    ),
                  ),
                ],
              ),
            ),
          if (hymn.alsoSungTo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l10n.alsoSungTo.toUpperCase(), style: theme.text.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tune in hymn.alsoSungTo) _TuneChip(tune)],
            ),
          ],
        ],
      ),
    );
  }
}

class _TuneChip extends StatelessWidget {
  const _TuneChip(this.tune);

  final AlsoSungTo tune;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final name = [
      if (tune.tune.isNotEmpty) tune.tune,
      if (tune.number != null) '${tune.number}',
    ].join(' · ');
    final hymnId = tune.hymnId;
    return ActionChip(
      onPressed: hymnId == null ? null : () => context.push(hymnPath(hymnId)),
      backgroundColor: theme.palette.tint,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      label: Text(
        hymnId == null ? '$name (${l10n.notInAppYet})' : name,
        style: theme.text.bodyStrong.copyWith(
          fontSize: 14,
          color: hymnId == null ? theme.palette.muted : theme.palette.primary,
        ),
      ),
    );
  }
}
