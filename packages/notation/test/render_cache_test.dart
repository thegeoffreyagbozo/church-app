import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/parts.dart';
import 'package:notation/src/render_cache.dart';

RenderKey _key(int verse, {Part? part}) => ('<xml/>', 400.0, verse, part, 40);

void main() {
  test('returns what was put for the same key', () {
    final cache = RenderCache()..put(_key(1), ['<svg/>']);

    expect(cache.get(_key(1)), ['<svg/>']);
    expect(cache.get(_key(2)), isNull);
    expect(cache.get(_key(1, part: Part.alto)), isNull);
  });

  test('drops the least recently used entry when full', () {
    final cache = RenderCache(capacity: 2)
      ..put(_key(1), ['one'])
      ..put(_key(2), ['two']);
    cache.get(_key(1)); // verse 1 is now the most recent
    cache.put(_key(3), ['three']);

    expect(cache.get(_key(2)), isNull);
    expect(cache.get(_key(1)), ['one']);
    expect(cache.get(_key(3)), ['three']);
  });
}
