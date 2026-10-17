import 'package:flutter/material.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/contents.dart';

/// The book's contents as a sheet: parts and their subheadings with number ranges.
/// Returns the row of the section list to jump to, or null when closed.
Future<int?> showContentsSheet(
  BuildContext context,
  SectionContents contents,
) => showModalBottomSheet<int>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
  ),
  builder: (context) => GlassSurface(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              AppLocalizations.of(context).contents,
              style: HymnalTheme.of(context).text.listTitle,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                for (final part in contents.parts) ...[
                  _Entry(
                    title: partTitle(part),
                    range: rangeLabel(part.lowest, part.highest),
                    strong: true,
                    row: contents.rowOf(part),
                  ),
                  for (final group in part.groups)
                    _Entry(
                      title: group.name,
                      range: rangeLabel(group.lowest, group.highest),
                      indent: true,
                      row: contents.rowOfGroup(group),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    required this.range,
    required this.row,
    this.strong = false,
    this.indent = false,
  });

  final String title;
  final String range;
  final int row;
  final bool strong;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).pop(row),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent ? 40 : 20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: strong ? theme.text.bodyStrong : theme.text.body,
                ),
              ),
              Text(range, style: theme.text.caption),
            ],
          ),
        ),
      ),
    );
  }
}
