import 'package:flutter/material.dart';

import '../theme/hymnal_theme.dart';

/// A list row for a hymn or reading: big number, optional kicker, title and a second
/// line. Used by Home, search results, section lists and the Readings tab.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.title,
    required this.onTap,
    this.number,
    this.kicker,
    this.subtitle,
    this.trailingLabel,
  });

  final int? number;

  /// Such as "SUPPLEMENTARY"; drawn in capitals.
  final String? kicker;

  /// The title, usually a [Text] or [HighlightedText].
  final Widget title;
  final Widget? subtitle;

  /// A small label at the right, such as a topic.
  final String? trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.palette.rule)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The column grows with the text size, and a number never breaks across
            // lines: "268" must not read as "26" above "8".
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.textScalerOf(context).scale(60),
              ),
              child: number == null
                  ? null
                  : Text(
                      '$number',
                      softWrap: false,
                      style: theme.text.listNumber,
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        kicker!.toUpperCase(),
                        style: theme.text.label,
                      ),
                    ),
                  DefaultTextStyle.merge(
                    style: theme.text.listTitle,
                    child: title,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: DefaultTextStyle.merge(
                        style: theme.text.listSubtitle,
                        child: subtitle!,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  trailingLabel!.toUpperCase(),
                  style: theme.text.listLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
