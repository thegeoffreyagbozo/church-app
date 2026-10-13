import 'dart:async';

import 'package:content_db/content_db.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/content_providers.dart';

/// Records that an item was opened, for "Recently opened" on Home.
class OpenedMarker extends ConsumerStatefulWidget {
  const OpenedMarker({
    super.key,
    required this.type,
    required this.id,
    required this.child,
  });

  final ItemType type;
  final String id;
  final Widget child;

  @override
  ConsumerState<OpenedMarker> createState() => _OpenedMarkerState();
}

class _OpenedMarkerState extends ConsumerState<OpenedMarker> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(markOpenedProvider)(widget.type, widget.id));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
