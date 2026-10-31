import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Side padding that keeps content in a readable column (at most [maxWidth] wide) on
/// tablets and in landscape, and [min] on phones.
double sidePadding(
  BuildContext context, {
  double min = 20,
  double maxWidth = 680,
}) => math.max(min, (MediaQuery.sizeOf(context).width - maxWidth) / 2);

/// Space after the last item of a list on a tab, so it scrolls clear of the bottom
/// edge.
double listBottomPadding(BuildContext context) =>
    24 + MediaQuery.paddingOf(context).bottom;

/// The width of an item page's content (hymns and readings): the screen less
/// [sidePadding] at its item-page minimum on each side. The Music view draws notation
/// this wide, and drawing ahead uses the same width so its results are reused.
double itemContentWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width - 2 * sidePadding(context, min: 22);
