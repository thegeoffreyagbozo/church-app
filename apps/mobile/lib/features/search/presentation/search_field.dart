import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../l10n/app_localizations.dart';

/// The one search bar (spec section 4): no buttons inside, a clear button once there
/// is text, and Go on the keyboard. Digits show as a hymn number. A tap anywhere else
/// hides the keyboard and keeps the words.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onGo,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onGo;

  static final _digits = RegExp(r'^\s*#?\d+\s*$');

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final l10n = AppLocalizations.of(context);
    // Taps on the bar, the clear button included, count as taps on the field.
    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          final focused = focusNode.hasFocus;
          final number = _digits.hasMatch(controller.text);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              color: theme.palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused ? theme.palette.primary : theme.palette.rule,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: focused
                  ? [BoxShadow(color: theme.palette.tint, spreadRadius: 4)]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 20,
                  color: theme.palette.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => onGo(),
                    onTapOutside: (_) => focusNode.unfocus(),
                    autocorrect: false,
                    style: number
                        ? theme.text.searchNumber
                        : theme.text.searchText,
                    cursorColor: theme.palette.accent,
                    decoration: InputDecoration.collapsed(
                      hintText: l10n.searchHint,
                      hintStyle: theme.text.searchText.copyWith(
                        color: theme.palette.muted,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: l10n.clearSearch,
                    onPressed: controller.clear,
                    icon: const Icon(LucideIcons.x, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.palette.tint,
                      foregroundColor: theme.palette.muted,
                      fixedSize: const Size.square(32),
                      minimumSize: const Size.square(48),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
