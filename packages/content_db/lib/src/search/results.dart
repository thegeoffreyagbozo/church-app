import 'package:shared/shared.dart';

import '../models.dart';

/// Marks the start of a matched word in [SearchHit.snippet].
const markStart = '\u0002';

/// Marks the end of a matched word in [SearchHit.snippet].
const markEnd = '\u0003';

/// Why an item was found, best first.
enum MatchKind { number, scripture, title, firstLine, text, credits }

/// One hymn or reading in the results.
class SearchHit {
  const SearchHit({
    required this.type,
    required this.id,
    required this.title,
    required this.match,
    this.number,
    this.section,
    this.readingKind,
    this.preview,
    this.snippet,
    this.sectionType,
    this.sectionNumber,
  });

  final ItemType type;
  final String id;
  final int? number;
  final String title;

  /// The hymn's section (null for readings).
  final Section? section;

  /// The reading's kind (null for hymns).
  final ReadingKind? readingKind;
  final MatchKind match;

  /// A hymn's first line, or the start of a reading.
  final String? preview;

  /// The matched text, with each matched word between [markStart] and [markEnd]; for a
  /// scripture match, the reference that matched.
  final String? snippet;

  /// For a match in a verse or chorus: which one.
  final HymnSectionType? sectionType;
  final int? sectionNumber;
}

/// A number that isn't in the section it was asked for, with the range that is.
class MissingNumber {
  const MissingNumber({
    required this.type,
    required this.number,
    this.sectionName,
    this.lowest,
    this.highest,
  });

  final ItemType type;
  final int number;

  /// The section searched (null for readings).
  final String? sectionName;
  final int? lowest;
  final int? highest;
}

class SearchResults {
  const SearchResults({
    required this.hits,
    this.exactTop = false,
    this.missing,
  });

  static const empty = SearchResults(hits: []);

  /// Best first; each item appears once.
  final List<SearchHit> hits;

  /// Whether the first hit is exactly the number asked for (shown large; Go opens it).
  final bool exactTop;

  /// Set when the number asked for isn't in that section.
  final MissingNumber? missing;
}
