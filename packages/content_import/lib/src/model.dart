/// One input file: its name (used in error messages) and its text.
class Source {
  const Source(this.name, this.text);
  final String name;
  final String text;
}

/// A problem in the input, pointing at the line to fix.
class Issue {
  const Issue(this.file, this.line, this.message, {this.isError = true});
  final String file;
  final int line;
  final String message;
  final bool isError;

  @override
  String toString() =>
      '$file:$line: ${isError ? 'error' : 'warning'}: $message';
}

/// A verse or chorus, in reading order (mirrors `hymn_sections`).
class HymnSection {
  HymnSection(this.type, this.number, this.lyrics);
  final String type; // verse, chorus or refrain
  final int? number;
  String lyrics;
}

/// Where a hymn sits in its section's contents, as the book prints them: a part such as
/// "Jesus Our Savior" and a subheading such as "His Birth". A part without subheadings
/// ("The Holy Spirit") has only a [name].
class Grouping {
  const Grouping(this.part, this.name);
  final String? part;
  final String name;
}

/// A hymn and its printed details (mirrors `hymns`).
class Hymn {
  Hymn(
    this.section,
    this.topic,
    this.number,
    this.file,
    this.line, {
    this.group,
  });
  final String section;
  final String? topic;
  final Grouping? group;
  final int? number;
  final String file;
  final int line;
  String? title, tune, words, music, arranged, translated, scripture;
  String? meter, musicKey, alsoSungTo, copyright;
  bool draft = false;
  final List<HymnSection> sections = [];
}

/// One line or paragraph of a reading (mirrors `reading_parts`).
class ReadingPart {
  ReadingPart(this.number, this.speaker, this.body);
  final int? number;
  String? speaker; // leader, people or all
  String body;
  String? ref;
}

/// A responsive reading, collection, creed or covenant (mirrors `readings`).
class Reading {
  Reading(this.kind, this.number, this.file, this.line);
  String kind; // a reading_kind value
  final int? number;
  final String file;
  final int line;
  String? title, scripture, copyright, readBy;
  bool draft = false;
  final List<ReadingPart> parts = [];
}

/// Everything parsed from one or more sources.
class Book {
  /// Section names in the order they first appear (each becomes a `hymnals` row).
  final List<String> sections = [];
  final List<Hymn> hymns = [];
  final List<Reading> readings = [];
  final List<Issue> issues = [];

  bool get hasErrors => issues.any((i) => i.isError);
}
