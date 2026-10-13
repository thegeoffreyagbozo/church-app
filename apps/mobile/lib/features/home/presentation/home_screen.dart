import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/church_config.dart';
import '../../../core/database/content_providers.dart';
import '../../../core/labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_row.dart';
import '../../../core/widgets/page_width.dart';
import '../../../l10n/app_localizations.dart';

/// The Hymns tab (spec section 3.1): church name, sections, recently opened. Search
/// joins in Task 15.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const _ChurchHeader(),
          const SizedBox(height: 18),
          _SectionChips(onOpen: (id) => context.go(sectionPath(id))),
          const SizedBox(height: 26),
          _RecentList(onOpen: (path) => context.push(path)),
        ],
      ),
    );
  }
}

class _ChurchHeader extends ConsumerWidget {
  const _ChurchHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HymnalTheme.of(context);
    final name = ref.watch(churchProvider).value?.name;
    final tagline = ref.watch(churchConfigProvider).tagline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name ?? AppLocalizations.of(context).appTitle,
            style: theme.text.churchName,
          ),
        ),
        if (tagline != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(tagline, style: theme.text.tagline),
          ),
      ],
    );
  }
}

class _SectionChips extends ConsumerWidget {
  const _SectionChips({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HymnalTheme.of(context);
    final sections = ref.watch(sectionsProvider).value ?? const [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final section in sections)
          // A plain pill rather than a Chip, so a long name wraps at large text sizes.
          Material(
            color: theme.palette.background,
            shape: StadiumBorder(side: BorderSide(color: theme.palette.rule)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onOpen(section.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(section.name, style: theme.text.body),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final recent = ref.watch(recentProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recentlyOpened.toUpperCase(), style: theme.text.listLabel),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.recentEmpty, style: theme.text.caption),
          ),
        for (final item in recent)
          ItemRow(
            number: item.number,
            kicker: item.type == ItemType.reading
                ? readingKicker(l10n, item.readingKind!)
                : (item.section == null || item.section!.isDefault
                      ? null
                      : hymnKicker(l10n, item.section!)),
            title: Text(item.title),
            subtitle: item.preview == null
                ? null
                : Text(
                    item.preview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => onOpen(
              item.type == ItemType.hymn
                  ? hymnPath(item.id)
                  : readingPath(item.id),
            ),
          ),
      ],
    );
  }
}
