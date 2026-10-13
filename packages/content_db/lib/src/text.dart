/// The first line of [text] as plain text: reading markup removed, at most [maxLength]
/// characters (cut at a word, with "…"). Null when there is no text.
String? previewLine(String? text, {int maxLength = 80}) {
  if (text == null) return null;
  for (final raw in text.split('\n')) {
    var line = raw.replaceAll('**', '').trim();
    if (line.startsWith('- ')) line = line.substring(2).trim();
    if (line.isEmpty) continue;
    if (line.length <= maxLength) return line;
    final cut = line.lastIndexOf(' ', maxLength);
    return '${line.substring(0, cut > 0 ? cut : maxLength)}…';
  }
  return null;
}

final _alsoSungTo = RegExp(
  r'^\s*also sung to\s*:\s*(.+)$',
  caseSensitive: false,
);
final _tuneAndNumber = RegExp(r'^(.*?)\s*\((\d+)\)$');

/// The tunes in an "Also sung to: Adeste Fideles (100), St. Denio (34)" line of
/// [choristerNotes], each with the hymn number in brackets when the book gives one.
List<({String tune, int? number})> parseAlsoSungTo(String? choristerNotes) {
  if (choristerNotes == null) return const [];
  for (final line in choristerNotes.split('\n')) {
    final match = _alsoSungTo.firstMatch(line);
    if (match == null) continue;
    return [
      for (final item in match[1]!.split(','))
        if (item.trim().isNotEmpty) _tune(item.trim()),
    ];
  }
  return const [];
}

({String tune, int? number}) _tune(String item) {
  final bare = int.tryParse(item);
  if (bare != null) return (tune: '', number: bare);
  final match = _tuneAndNumber.firstMatch(item);
  if (match == null) return (tune: item, number: null);
  return (tune: match[1]!, number: int.parse(match[2]!));
}
