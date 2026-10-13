import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';
import '../platform/platform_services.dart';

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
  late final ScreenAwake _screen;
  bool _awake = false;

  @override
  void initState() {
    super.initState();
    _screen = ref.read(screenAwakeProvider);
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
    unawaited(awake ? _screen.enable() : _screen.disable());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_awake) unawaited(_screen.disable());
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
