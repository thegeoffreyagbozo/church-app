import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import 'barlines.dart';
import 'flatten.dart';
import 'options.dart';
import 'parts.dart';
import 'raw_drawings.dart';
import 'render_cache.dart';
import 'resources.dart';
import 'verovio.dart';

/// Draws MusicXML with Verovio on one long-lived background isolate, which owns the only
/// toolkit (a toolkit must stay on one thread) and does all the XML work, so the screen
/// never waits on it. Requests queue to it in order. If the isolate stops, every drawing
/// still waiting fails with a [NotationException] instead of hanging.
class NotationEngine {
  NotationEngine._(this._requests, this.verovioVersion, this._inbox);

  final SendPort _requests;
  final ReceivePort _inbox;
  final _cache = RenderCache();
  final _pending = <int, Completer<List<String>>>{};
  var _nextId = 0;
  var _closed = false;

  /// Verovio's version string, for the Licences screen and logs.
  final String verovioVersion;

  /// Unpacks the fonts if needed and starts the drawing isolate.
  static Future<NotationEngine> start({AssetBundle? bundle}) async {
    final resources = await installResources(bundle ?? rootBundle);
    // Everything from the isolate arrives here: its port once ready, each drawing, and
    // its exit (null) or an uncaught error (a list) if it stops.
    final inbox = ReceivePort();
    final started = Completer<NotationEngine>();
    NotationEngine? engine;
    inbox.listen((message) {
      switch (message) {
        case (final SendPort requests, final String version):
          engine = NotationEngine._(requests, version, inbox);
          started.complete(engine);
        case (final int id, final Object result):
          engine?._reply(id, result);
        case final NotationException failure when engine == null:
          started.completeError(failure);
          inbox.close();
        default:
          final stopped = NotationException(
            'The drawing isolate stopped: $message',
          );
          if (engine case final running?) {
            running._stop(stopped);
          } else {
            if (!started.isCompleted) started.completeError(stopped);
            inbox.close();
          }
      }
    });
    await Isolate.spawn(
      _serve,
      (inbox.sendPort, resources),
      onExit: inbox.sendPort,
      onError: inbox.sendPort,
    );
    return started.future;
  }

  /// One SVG per page for [musicXml] drawn [width] logical pixels wide at [scale], with
  /// [verse]'s words under the notes and, when [part] is given, the other voices faded,
  /// barlines broken between the staves so they don't cross the words, reshaped so
  /// `flutter_svg` can draw it.
  Future<List<String>> render(
    String musicXml, {
    required double width,
    required int verse,
    Part? part,
    int scale = defaultScale,
  }) async {
    if (_closed) throw const NotationException('The engine has been disposed');
    final key = (musicXml, width, verse, part, scale);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final id = _nextId++;
    final drawing = Completer<List<String>>();
    _pending[id] = drawing;
    _requests.send((
      id,
      musicXml,
      verse,
      part,
      verovioOptions(width: width, scale: scale),
    ));
    final pages = await drawing.future;
    _cache.put(key, pages);
    return pages;
  }

  void _reply(int id, Object result) {
    final drawing = _pending.remove(id);
    if (drawing == null) return;
    if (result is List<String>) {
      drawing.complete(result);
    } else {
      drawing.completeError(
        result is NotationException ? result : NotationException('$result'),
      );
    }
  }

  void _stop(NotationException reason) {
    _closed = true;
    for (final drawing in _pending.values) {
      drawing.completeError(reason);
    }
    _pending.clear();
    _inbox.close();
  }

  /// Stops the isolate once the drawings already asked for are done; the engine can't
  /// draw after this.
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    _requests.send(null);
  }
}

void _serve((SendPort, String) start) {
  final (inbox, resources) = start;
  final Verovio verovio;
  try {
    verovio = Verovio.open(resources);
  } on Object catch (e) {
    inbox.send(NotationException('$e'));
    return;
  }
  final requests = ReceivePort();
  inbox.send((requests.sendPort, verovio.version));
  final raw = RawDrawings(verovio.render);
  requests.listen((message) {
    if (message == null) {
      verovio.dispose();
      requests.close();
      return;
    }
    final (id, musicXml, verse, part, options) =
        message as (int, String, int, Part?, String);
    try {
      inbox.send((id, _draw(raw, musicXml, verse, part, options)));
    } on NotationException catch (e) {
      inbox.send((id, e));
    } on XmlException catch (e) {
      inbox.send((id, NotationException('Not MusicXML: ${e.message}')));
    } on Object catch (e) {
      // Anything else must still answer, or the caller would wait forever.
      inbox.send((id, NotationException('$e')));
    }
  });
}

List<String> _draw(
  RawDrawings raw,
  String musicXml,
  int verse,
  Part? part,
  String options,
) => [
  for (final page in raw.draw(musicXml, verse, options))
    flattenForFlutter(
      breakBarlinesBetweenStaves(
        part == null ? page : fadeOtherParts(page, part),
      ),
    ),
];
