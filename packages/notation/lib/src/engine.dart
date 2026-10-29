import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import 'options.dart';
import 'parts.dart';
import 'render_cache.dart';
import 'resources.dart';
import 'verovio.dart';
import 'verses.dart';

/// Draws MusicXML with Verovio on one long-lived background isolate, which owns the only
/// toolkit (a toolkit must stay on one thread). Requests queue to it in order.
class NotationEngine {
  NotationEngine._(this._requests, this.verovioVersion);

  final SendPort _requests;
  final _cache = RenderCache();

  /// Verovio's version string, for the Licences screen and logs.
  final String verovioVersion;

  /// Unpacks the fonts if needed and starts the drawing isolate.
  static Future<NotationEngine> start({AssetBundle? bundle}) async {
    final resources = await installResources(bundle ?? rootBundle);
    final ready = ReceivePort();
    await Isolate.spawn(_serve, (ready.sendPort, resources));
    final reply = await ready.first;
    if (reply is NotationException) throw reply;
    final (requests, version) = reply as (SendPort, String);
    return NotationEngine._(requests, version);
  }

  /// One SVG per page for [musicXml] drawn [width] logical pixels wide at [scale], with
  /// [verse]'s words under the notes and, when [part] is given, the other voices faded.
  Future<List<String>> render(
    String musicXml, {
    required double width,
    required int verse,
    Part? part,
    int scale = defaultScale,
  }) async {
    final key = (musicXml, width, verse, part, scale);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final String data;
    try {
      data = keepVerse(musicXml, verse);
    } on XmlException catch (e) {
      throw NotationException('Not MusicXML: ${e.message}');
    }
    final reply = ReceivePort();
    _requests.send((reply.sendPort, data, verovioOptions(width: width, scale: scale)));
    final result = await reply.first;
    if (result is NotationException) throw result;
    final drawn = result as List<String>;
    final pages = part == null ? drawn : [for (final page in drawn) fadeOtherParts(page, part)];
    _cache.put(key, pages);
    return pages;
  }

  /// Stops the isolate; the engine can't draw after this.
  Future<void> dispose() async => _requests.send(null);
}

void _serve((SendPort, String) start) {
  final (ready, resources) = start;
  final Verovio verovio;
  try {
    verovio = Verovio.open(resources);
  } on Object catch (e) {
    ready.send(NotationException('$e'));
    return;
  }
  final requests = ReceivePort();
  ready.send((requests.sendPort, verovio.version));
  requests.listen((message) {
    if (message == null) {
      verovio.dispose();
      requests.close();
      return;
    }
    final (reply, data, options) = message as (SendPort, String, String);
    try {
      reply.send(verovio.render(data, options));
    } on NotationException catch (e) {
      reply.send(e);
    }
  });
}
