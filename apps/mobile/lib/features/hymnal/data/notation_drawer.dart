import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notation/notation.dart';
import 'package:shared/shared.dart';

import '../../../core/database/content_providers.dart';
import '../../settings/domain/reading_settings.dart';

/// Draws a hymn's notation. The app uses Verovio; tests use a fake, since the native
/// library can't load under `flutter test`.
abstract interface class NotationDrawer {
  /// Starts the engine ahead of the first drawing.
  void warmUp();

  Future<List<String>> draw(
    String musicXml, {
    required double width,
    required int verse,
    required HymnPart part,
    required int scale,
  });
}

/// The real drawer: one Verovio engine for the whole app, started on first use.
class VerovioDrawer implements NotationDrawer {
  late final Future<NotationEngine> _engine = NotationEngine.start();

  // Touching the field starts the engine; ignore() keeps an early failure from being
  // reported as unhandled, and the first draw rethrows it.
  @override
  void warmUp() => _engine.ignore();

  @override
  Future<List<String>> draw(
    String musicXml, {
    required double width,
    required int verse,
    required HymnPart part,
    required int scale,
  }) async => (await _engine).render(
    musicXml,
    width: width,
    verse: verse,
    part: part.notationPart,
    scale: scale,
  );
}

final notationDrawerProvider = Provider<NotationDrawer>(
  (ref) => VerovioDrawer(),
);

/// A hymn's MusicXML, unpacked from the hymn book; null when it has no notation.
final hymnNotationProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  final bytes = await ref.watch(catalogProvider).notation(id);
  return bytes == null ? null : musicXmlFromFile(bytes);
});

/// One drawing of a hymn's notation.
typedef NotationRequest = ({
  String hymnId,
  double width,
  int verse,
  HymnPart part,
  int scale,
});

final notationDrawingProvider = FutureProvider.autoDispose
    .family<List<String>, NotationRequest>((ref, r) async {
      final musicXml = await ref.watch(hymnNotationProvider(r.hymnId).future);
      if (musicXml == null) throw const NotationException('no notation');
      return ref
          .watch(notationDrawerProvider)
          .draw(
            musicXml,
            width: r.width,
            verse: r.verse,
            part: r.part,
            scale: r.scale,
          );
    });
