import 'package:xml/xml.dart';

final _vertical = RegExp(r'^M(\S+) (\S+) L(\S+) (\S+)$');

/// [svg] from Verovio with each barline broken where it would cross the gap between
/// the two staves, where the words sit. Verovio draws a barline as one piece per staff
/// plus a piece joining them; the joining piece is the one that starts where another
/// piece at the same x ends, and ends where a third begins.
String breakBarlinesBetweenStaves(String svg) {
  final document = XmlDocument.parse(svg);
  final barlines = document
      .findAllElements('g')
      .where(
        (g) => (g.getAttribute('class') ?? '').split(' ').contains('barLine'),
      );
  for (final barline in barlines) {
    final lines = [
      for (final path in barline.findElements('path'))
        if (_vertical.firstMatch(path.getAttribute('d') ?? '') case final m?
            when m[1] == m[3])
          (path: path, x: m[1]!, top: m[2]!, bottom: m[4]!),
    ];
    for (final line in lines) {
      final sameX = lines.where((other) => other.x == line.x && other != line);
      final joinsAbove = sameX.any((other) => other.bottom == line.top);
      final joinsBelow = sameX.any((other) => other.top == line.bottom);
      if (joinsAbove && joinsBelow) line.path.remove();
    }
  }
  return document.toXmlString();
}
