import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/item_row.dart';
import '../../../core/widgets/page_width.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/hymnal_providers.dart';

/// All hymns of one section: by number, or in book order with their topic when the
/// section is unnumbered (spec section 3.2).
class SectionListScreen extends ConsumerWidget {
  const SectionListScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HymnalTheme.of(context);
    final section = ref.watch(sectionProvider(sectionId)).value;
    final hymns = ref.watch(sectionHymnsProvider(sectionId)).value ?? const [];
    final side = sidePadding(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    icon: LucideIcons.chevronLeft,
                    label: AppLocalizations.of(context).back,
                    onPressed: () => context.pop(),
                  ),
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
              sliver: SliverList.builder(
                itemCount: hymns.length,
                itemBuilder: (context, i) {
                  final hymn = hymns[i];
                  return ItemRow(
                    number: hymn.number,
                    title: Text(hymn.title),
                    subtitle: hymn.firstLine == null
                        ? null
                        : Text(hymn.firstLine!),
                    trailingLabel: hymn.number == null ? hymn.topic : null,
                    onTap: () => context.push(hymnPath(hymn.id)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
