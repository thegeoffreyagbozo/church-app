import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';
import '../platform/platform_services.dart';

/// Counts the pages keeping the screen awake, so it sleeps only when the last one lets
/// go: closing a hymn opened from another hymn must not let the first one sleep.
class ScreenAwakeHolds {
  ScreenAwakeHolds(this._screen);

  final ScreenAwake _screen;
  int _holds = 0;

  void hold() {
    if (_holds++ == 0) unawaited(_screen.enable());
  }

  void release() {
    if (--_holds == 0) unawaited(_screen.disable());
  }
}

final screenAwakeHoldsProvider = Provider<ScreenAwakeHolds>(
  (ref) => ScreenAwakeHolds(ref.watch(screenAwakeProvider)),
);

/// Keeps the screen awake while [child] is shown, if the setting is on. Releases it when
/// the page closes or the app goes to the background (spec section 3.3).
class KeepScreenOn extends ConsumerStatefulWidget {
  const KeepScreenOn({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends ConsumerState<KeepScreenOn> {
  late final AppLifecycleListener _lifecycle;
  late final ScreenAwakeHolds _holds;
  bool _awake = false;

  @override
  void initState() {
    super.initState();
    _holds = ref.read(screenAwakeHoldsProvider);
    _lifecycle = AppLifecycleListener(
      onResume: _sync,
      onHide: () => _set(false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    _set(ref.read(readingSettingsProvider).keepScreenOn);
  }

  void _set(bool awake) {
    if (awake == _awake) return;
    _awake = awake;
    awake ? _holds.hold() : _holds.release();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_awake) _holds.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      readingSettingsProvider.select((s) => s.keepScreenOn),
      (_, on) => _set(on),
    );
    return widget.child;
  }
}
