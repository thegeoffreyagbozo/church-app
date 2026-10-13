import 'package:flutter/widgets.dart';

/// Rebuilds with whether the on-screen keyboard is up. Reads the window itself, because
/// a Scaffold hides the keyboard's height from the widgets in its body.
class KeyboardVisibility extends StatefulWidget {
  const KeyboardVisibility({super.key, required this.builder});

  final Widget Function(BuildContext context, bool visible) builder;

  @override
  State<KeyboardVisibility> createState() => _KeyboardVisibilityState();
}

class _KeyboardVisibilityState extends State<KeyboardVisibility>
    with WidgetsBindingObserver {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    final visible = View.of(context).viewInsets.bottom > 0;
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _visible);
}
