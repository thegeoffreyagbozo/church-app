import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/labels.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/highlighted_text.dart';
import '../../../core/widgets/item_row.dart';
import '../../../l10n/app_localizations.dart';
import '../data/search_providers.dart';

/// Results in place of Home's lists while searching (spec section 4).
class SearchResultsView extends ConsumerWidget {
  const SearchResultsView({super.key, required this.onOpen});

  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final results = ref.watch(searchResultsProvider).value;
    if (results == null) return const SizedBox.shrink();
    final rows = results.exactTop
        ? results.hits.skip(1).toList()
        : results.hits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (results.missing case final missing?)
          _Notice(_missingText(l10n, missing)),
        if (results.exactTop) _TopHit(results.hits.first, onOpen: onOpen),
        if (rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 2),
            child: Text(
              l10n.resultCount(rows.length).toUpperCase(),
              style: theme.text.listLabel,
            ),
          ),
        for (final hit in rows) _HitRow(hit, onOpen: onOpen),
        if (results.hits.isEmpty && results.missing == null)
          _Notice(l10n.noMatches(ref.watch(searchQueryProvider).trim())),
      ],
    );
  }

  static String _missingText(AppLocalizations l10n, MissingNumber missing) {
    final lowest = missing.lowest ?? 1;
    final highest = missing.highest ?? 0;
    return missing.type == ItemType.reading
        ? l10n.missingReading(missing.number, lowest, highest)
        : l10n.missingHymn(
            missing.number,
            missing.sectionName!,
            lowest,
            highest,
          );
  }
}

String? _kicker(AppLocalizations l10n, SearchHit hit) {
  if (hit.type == ItemType.reading) {
    return readingKicker(l10n, hit.readingKind!);
  }
  final section = hit.section;
  return section == null || section.isDefault
      ? null
      : hymnKicker(l10n, section);
}

class _HitRow extends StatelessWidget {
  const _HitRow(this.hit, {required this.onOpen});

  final SearchHit hit;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final highlight = theme.palette.accent.withValues(alpha: 0.14);
    final snippet = hit.snippet;
    final Widget title = hit.match == MatchKind.title && snippet != null
        ? HighlightedText(
            snippet,
            style: theme.text.listTitle,
            highlight: highlight,
          )
        : Text(hit.title);
    final Widget? subtitle = switch (hit.match) {
      MatchKind.firstLine ||
      MatchKind.text ||
      MatchKind.credits when snippet != null => HighlightedText(
        snippet,
        maxLines: 2,
        style: theme.text.listSubtitle,
        highlight: highlight,
        prefix: hit.sectionType == null
            ? null
            : TextSpan(
                text:
                    '${sectionLabel(l10n, hit.sectionType!, hit.sectionNumber).toUpperCase()}  ',
                style: theme.text.label,
              ),
      ),
      MatchKind.scripture when snippet != null => Text(snippet),
      _ when hit.preview != null => Text(
        hit.preview!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      _ => null,
    };
    return ItemRow(
      number: hit.number,
      kicker: _kicker(l10n, hit),
      title: title,
      subtitle: subtitle,
      onTap: () => onOpen(hit),
    );
  }
}

/// The large card for an exact number match; the keyboard's Go opens it.
class _TopHit extends StatelessWidget {
  const _TopHit(this.hit, {required this.onOpen});

  final SearchHit hit;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final kicker = hit.type == ItemType.reading
        ? readingKicker(l10n, hit.readingKind!)
        : hymnKicker(l10n, hit.section!);
    return Material(
      color: theme.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.palette.rule),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onOpen(hit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${hit.number}', style: theme.text.topHitNumber),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker.toUpperCase(), style: theme.text.label),
                    const SizedBox(height: 2),
                    Text(hit.title, style: theme.text.listTitle),
                    const SizedBox(height: 2),
                    Text(l10n.pressGo, style: theme.text.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.palette.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: theme.text.body),
    );
  }
}
