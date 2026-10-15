import 'package:flutter/material.dart';

import '../theme/hymnal_theme.dart';
import 'glass_surface.dart';

/// Shows a glass menu under the button whose key is [anchorKey] (the `···` menu).
Future<void> showGlassMenu(
  BuildContext context, {
  required GlobalKey anchorKey,
  required WidgetBuilder builder,
}) {
  final box = anchorKey.currentContext!.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero) & box.size;
  return Navigator.of(context).push(
    _GlassMenuRoute(
      anchor: anchor,
      builder: builder,
      barrierColor: HymnalTheme.of(context).palette.scrim,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

class _GlassMenuRoute extends PopupRoute<void> {
  _GlassMenuRoute({
    required this.anchor,
    required this.builder,
    required this.barrierColor,
    required this.barrierLabel,
  });

  final Rect anchor;
  final WidgetBuilder builder;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CustomSingleChildLayout(
      delegate: _MenuLayout(anchor, MediaQuery.paddingOf(context)),
      child: SizedBox(
        width: 288,
        child: GlassSurface(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: builder(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        alignment: Alignment.topRight,
        scale: Tween(begin: 0.92, end: 1.0).animate(curve),
        child: child,
      ),
    );
  }
}

/// Places the menu below the anchor, right edges aligned, inside the safe area.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.padding);

  final Rect anchor;
  final EdgeInsets padding;
  static const _margin = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        constraints.biggest,
      ).deflate(padding + const EdgeInsets.all(_margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final right = anchor.right.clamp(
      childSize.width + _margin,
      size.width - _margin,
    );
    final top = (anchor.bottom + 8).clamp(
      padding.top + _margin,
      size.height - padding.bottom - childSize.height - _margin,
    );
    return Offset(right - childSize.width, top);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      anchor != old.anchor || padding != old.padding;
}
