import 'parts.dart';

/// What a drawing depends on. The theme isn't part of it: the widget tints the drawing.
typedef RenderKey = (
  String musicXml,
  double width,
  int verse,
  Part? part,
  int scale,
);

/// The last [capacity] drawings, least recently used dropped first.
class RenderCache {
  RenderCache({this.capacity = 20});

  final int capacity;

  // A Dart map literal keeps insertion order: the first key is the least recently used.
  final _entries = <RenderKey, List<String>>{};

  List<String>? get(RenderKey key) {
    final pages = _entries.remove(key);
    if (pages != null) _entries[key] = pages;
    return pages;
  }

  void put(RenderKey key, List<String> pages) {
    _entries.remove(key);
    _entries[key] = pages;
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
  }
}
