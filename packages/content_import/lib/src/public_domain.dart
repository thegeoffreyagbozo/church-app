/// "1784-1872", "c. 1510-c. 1561", or an open "1921-" (the person was alive when printed).
final _lifeSpan = RegExp(r'(\d{4})\s*-\s*(?:c\.\s*)?(\d{4})?');
final _year = RegExp(r'\b(\d{4})\b');
final _traditional =
    RegExp(r'\b(traditional|anonymous)\b', caseSensitive: false);

/// Whether a hymn with these printed [credits] is in the public domain in [currentYear].
///
/// Ghana protects works for the author's life plus 70 years, so a work is free from the
/// 1st of January after 70 full years have passed since the latest death among its
/// credits. Credits without dates cannot be confirmed, so they count as protected. A
/// [copyright] label, when given, decides on its own.
bool isPublicDomain(
  List<String> credits, {
  required int currentYear,
  String? copyright,
}) {
  if (copyright != null) {
    return copyright.trim().toLowerCase() == 'public domain';
  }
  if (credits.isEmpty) return false;
  final latestFreeDeathYear = currentYear - 71;
  return credits.every((c) => _isFree(c, latestFreeDeathYear));
}

bool _isFree(String credit, int latestFreeDeathYear) {
  if (_traditional.hasMatch(credit)) return true;
  final spans = _lifeSpan.allMatches(credit).toList();
  if (spans.isNotEmpty) {
    return spans.every(
      (s) =>
          s.group(2) != null && int.parse(s.group(2)!) <= latestFreeDeathYear,
    );
  }
  // No life span: an anonymous source counts from its publication year.
  final years = _year.allMatches(credit).map((m) => int.parse(m.group(1)!));
  return years.isNotEmpty &&
      years.reduce((a, b) => a > b ? a : b) <= latestFreeDeathYear;
}
