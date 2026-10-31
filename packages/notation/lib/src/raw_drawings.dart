import 'verses.dart';

/// Verovio drawing [musicXml] with an options JSON, one SVG per page.
typedef VerovioRender = List<String> Function(String musicXml, String options);

/// Verovio's drawings before any part is faded, kept for the [capacity] most recently
/// used verses and sizes, so changing part only re-fades and never runs Verovio.
class RawDrawings {
  RawDrawings(this._render, {this.capacity = 20});

  final VerovioRender _render;
  final int capacity;
  final _entries = <(String, int, String), List<String>>{};

  List<String> draw(String musicXml, int verse, String options) {
    final key = (musicXml, verse, options);
    final hit = _entries.remove(key);
    if (hit != null) return _entries[key] = hit;
    final pages = _render(keepVerse(musicXml, verse), options);
    _entries[key] = pages;
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
    return pages;
  }
}
