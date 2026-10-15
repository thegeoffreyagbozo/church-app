import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../core/labels.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../l10n/app_localizations.dart';

/// A verse with its number in the margin, or a chorus indented behind a rule.
class HymnTextBlock extends StatelessWidget {
  const HymnTextBlock(this.text, {super.key});

  final HymnText text;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    if (text.isChorus) {
      return Padding(
        padding: const EdgeInsets.only(left: 30, bottom: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.palette.primary, width: 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionLabel(
                    AppLocalizations.of(context),
                    text.type,
                    text.number,
                  ).toUpperCase(),
                  style: theme.text.label,
                ),
                const SizedBox(height: 4),
                Text(text.lyrics, style: theme.text.chorus),
              ],
            ),
          ),
        ),
      );
    }
    final number = text.type == HymnSectionType.verse ? text.number : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Grows with the text size; a verse number never breaks across lines.
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.textScalerOf(context).scale(30),
            ),
            child: Text(
              number == null ? '' : '$number',
              softWrap: false,
              style: theme.text.verseNumber,
            ),
          ),
          Expanded(child: Text(text.lyrics, style: theme.text.verse)),
        ],
      ),
    );
  }
}
