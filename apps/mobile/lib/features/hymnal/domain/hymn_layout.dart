import 'package:content_db/content_db.dart';
import 'package:shared/shared.dart';

/// The verses and choruses to show, with the chorus repeated in full after every verse
/// (spec section 3.3). Only a hymn with exactly one chorus or refrain repeats it; one
/// that prints several keeps the book's order.
List<HymnText> withChorusAfterEachVerse(List<HymnText> texts) {
  final choruses = texts.where((t) => t.isChorus).toList();
  if (choruses.length != 1) return texts;
  final chorus = choruses.single;
  return [
    for (final (i, text) in texts.indexed) ...[
      text,
      if (text.type == HymnSectionType.verse &&
          !(i + 1 < texts.length && texts[i + 1].isChorus))
        chorus,
    ],
  ];
}

/// The credits line under the title, as printed: words, then music.
/// "Edmond L. Budry; translated by Richard B. Hoyle" reads as
/// "Edmond L. Budry, translated by Richard B. Hoyle".
String? creditsLine(String? author, String? composer) {
  final parts = [
    for (final credit in [author, composer])
      if (credit != null && credit.trim().isNotEmpty)
        credit.replaceAll('; ', ', '),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
