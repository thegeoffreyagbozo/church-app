import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_row.dart';
import '../../../core/widgets/page_width.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/hymnal_providers.dart';
import '../domain/contents.dart';
import 'contents_sheet.dart';

/// All hymns of one section: by number, or in book order with their topic when the
/// section is unnumbered (spec section 3.2). When the book gives the section contents
/// headings, their titles head the hymns and a Contents button jumps to them.
class SectionListScreen extends ConsumerStatefulWidget {
  const SectionListScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  ConsumerState<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends ConsumerState<SectionListScreen> {
  final _scroll = ScrollController();
  final _list = ListController();

  @override
  void dispose() {
    _list.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openContents(SectionContents contents) async {
    final row = await showContentsSheet(context, contents);
    if (row == null || !mounted) return;
    _list.jumpToItem(index: row, scrollController: _scroll, alignment: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final section = ref.watch(sectionProvider(widget.sectionId)).value;
    final contents = ref.watch(sectionContentsProvider(widget.sectionId)).value;
    final rows = contents?.rows ?? const <SectionRow>[];
    final side = sidePadding(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: LucideIcons.chevronLeft,
                      label: l10n.back,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    if (contents != null && contents.parts.isNotEmpty)
                      RoundIconButton(
                        icon: LucideIcons.tableOfContents,
                        label: l10n.contents,
                        onPressed: () => _openContents(contents),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 12, side, 8),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  header: true,
                  child: Text(
                    section?.name ?? '',
                    style: theme.text.screenTitle,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                side,
                0,
                side,
                listBottomPadding(context),
              ),
              sliver: SuperSliverList.builder(
                listController: _list,
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  PartRow(:final part) => _PartTitle(part),
                  GroupRow(:final group) => _GroupTitle(group),
                  HymnEntry(:final hymn) => ItemRow(
                    number: hymn.number,
                    title: Text(hymn.title),
                    subtitle: hymn.firstLine == null
                        ? null
                        : Text(hymn.firstLine!),
                    trailingLabel: hymn.number == null ? hymn.topic : null,
                    onTap: () => context.push(hymnPath(hymn.id)),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "II. JESUS OUR SAVIOR", with the range when the part has no subheadings.
class _PartTitle extends StatelessWidget {
  const _PartTitle(this.part);

  final ContentsPart part;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                partTitle(part).toUpperCase(),
                style: theme.text.label,
              ),
            ),
            if (part.groups.isEmpty)
              Text(
                rangeLabel(part.lowest, part.highest),
                style: theme.text.listLabel,
              ),
          ],
        ),
      ),
    );
  }
}

/// "His Birth" with its range.
class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.group);

  final ContentsGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 2),
        child: Row(
          children: [
            Expanded(child: Text(group.name, style: theme.text.bodyStrong)),
            Text(
              rangeLabel(group.lowest, group.highest),
              style: theme.text.caption,
            ),
          ],
        ),
      ),
    );
  }
}
