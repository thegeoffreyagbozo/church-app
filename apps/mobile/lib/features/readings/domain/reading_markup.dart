/// One line of a reading part: a paragraph or a bullet, made of plain and bold runs.
class MarkupLine {
  const MarkupLine(this.runs, {this.bullet = false});

  final List<MarkupRun> runs;
  final bool bullet;

  String get text => runs.map((r) => r.text).join();
}

class MarkupRun {
  const MarkupRun(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  bool operator ==(Object other) =>
      other is MarkupRun && other.text == text && other.bold == bold;

  @override
  int get hashCode => Object.hash(text, bold);

  @override
  String toString() => bold ? '**$text**' : text;
}

/// Reads the small markup reading parts may hold (ADR 0008): line breaks, "- " bullets
/// and **bold**. An unclosed ** is shown as typed, so nothing is ever hidden.
List<MarkupLine> parseReadingMarkup(String body) => [
  for (final raw in body.split('\n'))
    if (raw.trim().isNotEmpty) _line(raw.trim()),
];

MarkupLine _line(String raw) {
  final bullet = raw.startsWith('- ');
  final text = bullet ? raw.substring(2).trimLeft() : raw;
  final pieces = text.split('**');
  // An even number of pieces means an odd number of ** markers: one is unclosed.
  if (pieces.length.isEven) {
    return MarkupLine([MarkupRun(text)], bullet: bullet);
  }
  return MarkupLine([
    for (final (i, piece) in pieces.indexed)
      if (piece.isNotEmpty) MarkupRun(piece, bold: i.isOdd),
  ], bullet: bullet);
}

/// [body] as plain text for sharing: no ** markers, bullets as "•".
String plainReadingText(String body) => [
  for (final line in parseReadingMarkup(body))
    '${line.bullet ? '• ' : ''}${line.text}',
].join('\n');
