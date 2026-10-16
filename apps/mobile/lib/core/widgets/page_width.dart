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
