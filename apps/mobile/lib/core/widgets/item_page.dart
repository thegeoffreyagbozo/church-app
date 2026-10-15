import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../features/settings/presentation/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/hymnal_theme.dart';
import '../theme/reading_text_scale.dart';
import 'glass_surface.dart';
import 'keep_screen_on.dart';
import 'page_width.dart';
import 'pinch_to_resize.dart';
import 'round_icon_button.dart';

/// The layout shared by hymn and reading pages (spec sections 3.3 and 3.5): a back
/// button and [actions] at the top, then the kicker, big number, title and [subtitle],
/// then [children] at the reader's text size. Once the number scrolls away a glass
/// header pins the number and title. Pinching changes the text size and the screen is
/// kept on.
class ItemPage extends ConsumerStatefulWidget {
  const ItemPage({
    super.key,
    required this.kicker,
    required this.title,
    required this.actions,
    required this.children,
    this.number,
    this.subtitle,
  });

  final String kicker;
  final int? number;
  final String title;

  /// Credits or a scripture reference, in italic under the title.
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  ConsumerState<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends ConsumerState<ItemPage> {
  static const _barHeight = 60.0;
  final _scroll = ScrollController();
  final _titleKey = GlobalKey();
  bool _scrolled = false;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Glass once the page moves; number and title once the title slides under the bar.
  /// The title's place on the page is measured, not its place on screen, because a
  /// scroll listener runs before the new positions are laid out.
  void _onScroll() {
    final box = _titleKey.currentContext?.findRenderObject();
    final barBottom = MediaQuery.paddingOf(context).top + _barHeight;
    final titleTop = box == null
        ? double.infinity
        : RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
    final scrolled = _scroll.offset > 2;
    final compact = _scroll.offset > titleTop - barBottom;
    if (scrolled != _scrolled || compact != _compact) {
      setState(() {
        _scrolled = scrolled;
        _compact = compact;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final padding = MediaQuery.paddingOf(context);
    final side = sidePadding(context, min: 22);
    final settings = ref.watch(readingSettingsProvider);
    final controller = ref.read(readingSettingsProvider.notifier);
    return Scaffold(
      body: KeepScreenOn(
        child: Stack(
          children: [
            PinchToResize(
              scale: settings.textScale,
              onChanged: controller.previewTextScale,
              onEnd: controller.commitTextScale,
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  // A box adapter keeps the header built however far the page
                  // scrolls; the pinned bar measures the title in it.
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      padding.top + _barHeight + 8,
                      side,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.kicker.toUpperCase(),
                            style: theme.text.kicker,
                          ),
                          if (widget.number != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${widget.number}',
                                style: theme.text.bigNumber,
                              ),
                            ),
                          Padding(
                            key: _titleKey,
                            padding: const EdgeInsets.only(top: 6),
                            child: Semantics(
                              header: true,
                              child: Text(
                                widget.title,
                                style: theme.text.pageTitle,
                              ),
                            ),
                          ),
                          if (widget.subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                widget.subtitle!,
                                style: theme.text.credits,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(color: theme.palette.rule),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      0,
                      side,
                      48 + padding.bottom,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // Only the words take the reader's text size; the header
                        // keeps the phone's, so the number never crowds them out.
                        ReadingTextScale(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.children,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                height: _barHeight,
                glass: _scrolled,
                compact: _compact,
                number: widget.number,
                title: widget.title,
                actions: widget.actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.glass,
    required this.compact,
    required this.number,
    required this.title,
    required this.actions,
  });

  final double height;
  final bool glass;
  final bool compact;
  final int? number;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final bar = Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              RoundIconButton(
                icon: LucideIcons.chevronLeft,
                label: l10n.back,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: compact
                      ? Row(
                          key: const ValueKey('compact-title'),
                          children: [
                            if (number != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '$number',
                                  style: theme.text.itemNumber,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text.listTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
    if (!glass) return bar;
    return GlassSurface(
      border: false,
      shadow: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.palette.rule)),
        ),
        child: bar,
      ),
    );
  }
}
