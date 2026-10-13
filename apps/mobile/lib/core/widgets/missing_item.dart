import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/hymnal_theme.dart';
import 'round_icon_button.dart';

/// Shown when a link points at a hymn or reading that is no longer in the book.
class MissingItem extends StatelessWidget {
  const MissingItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundIconButton(
                icon: LucideIcons.chevronLeft,
                label: l10n.back,
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.itemMissing,
                    style: HymnalTheme.of(context).text.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
