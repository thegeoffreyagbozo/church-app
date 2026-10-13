import 'package:flutter/widgets.dart';

/// Turns a two-finger pinch into a text size, without taking part in gestures, so the
/// page keeps scrolling with one finger.
class PinchToResize extends StatefulWidget {
  const PinchToResize({
    super.key,
    required this.scale,
    required this.onChanged,
    required this.onEnd,
    required this.child,
  });

  /// The text size when the pinch starts.
  final double scale;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;
  final Widget child;

  @override
  State<PinchToResize> createState() => _PinchToResizeState();
}

class _PinchToResizeState extends State<PinchToResize> {
  final _pointers = <int, Offset>{};
  double? _startDistance;
  double _startScale = 1;

  double get _distance {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _down(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 2) {
      _startDistance = _distance;
      _startScale = widget.scale;
    }
  }

  void _move(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    final start = _startDistance;
    if (start == null || start == 0 || _pointers.length < 2) return;
    widget.onChanged(_startScale * _distance / start);
  }

  void _up(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_startDistance != null && _pointers.length < 2) {
      _startDistance = null;
      widget.onEnd();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: widget.child,
  );
}
