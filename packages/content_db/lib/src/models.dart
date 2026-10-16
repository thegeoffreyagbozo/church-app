import 'package:shared/shared.dart';

/// What a search hit, a recently opened entry or a link points at.
enum ItemType {
  hymn('hymn'),
  reading('reading');

  const ItemType(this.wireValue);
  final String wireValue;

  static ItemType fromWire(String value) =>
      value == reading.wireValue ? reading : hymn;
}

/// A numbering series of the book (`hymnals` row) that holds at least one hymn.
class Section {
  const Section({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.count,
    this.lowestNumber,
    this.highestNumber,
  });

  final String id;
  final String name;

  /// Whether a bare number such as "268" means this series. At most one section is the
  /// default: the first one marked `is_default` that has numbers, else the first one
  /// that has numbers.
  final bool isDefault;

  /// How many hymns it holds.
  final int count;
  final int? lowestNumber;
  final int? highestNumber;

  /// Whether its hymns have numbers (Service Music, for example, has none).
  bool get isNumbered => highestNumber != null;
}

/// A row of a section list.
class HymnListItem {
  const HymnListItem({
    required this.id,
    required this.title,
    this.number,
    this.firstLine,
    this.topic,
  });

  final String id;
  final int? number;
  final String title;
  final String? firstLine;

  /// The hymn's topic, such as Communion.
  final String? topic;
}

/// A verse or chorus as printed.
class HymnText {
  const HymnText({required this.type, required this.lyrics, this.number});

  final HymnSectionType type;
  final int? number;
  final String lyrics;

  bool get isChorus =>
      type == HymnSectionType.chorus || type == HymnSectionType.refrain;
}

/// Another tune the book says a hymn can be sung to, such as "Adeste Fideles (100)".
class AlsoSungTo {
  const AlsoSungTo({required this.tune, this.number, this.hymnId});

  final String tune;

  /// The number of the hymn that tune belongs to, in the default section.
  final int? number;

  /// That hymn's id, or null when it isn't in the app.
  final String? hymnId;
}

class HymnDetail {
  const HymnDetail({
    required this.id,
    required this.section,
    required this.title,
    required this.isPublicDomain,
    required this.texts,
    required this.alsoSungTo,
    this.number,
    this.author,
    this.composer,
    this.tuneName,
    this.meter,
    this.musicKey,
    this.topic,
  });

  final String id;
  final Section section;
  final int? number;
  final String title;

  /// Words credit as printed, e.g. "Edmond L. Budry; translated by Richard B. Hoyle".
  final String? author;

  /// Music credit as printed (the Music view calls it the tune source).
  final String? composer;
  final String? tuneName;
  final String? meter;
  final String? musicKey;
  final String? topic;

  /// Whether the words may be shared (copyright expired or waived).
  final bool isPublicDomain;

  /// Verses and choruses in book order, each printed once.
  final List<HymnText> texts;
  final List<AlsoSungTo> alsoSungTo;
}

class ReadingListItem {
  const ReadingListItem({
    required this.id,
    required this.kind,
    required this.title,
    this.number,
    this.scriptureRef,
    this.preview,
  });

  final String id;
  final ReadingKind kind;
  final int? number;
  final String title;
  final String? scriptureRef;

  /// The start of the first part, as plain text.
  final String? preview;
}

class ReadingPartText {
  const ReadingPartText({
    required this.body,
    this.number,
    this.speaker,
    this.scriptureRef,
  });

  /// May hold line breaks, `- ` bullets and `**bold**` (ADR 0008).
  final String body;
  final int? number;
  final ReadingSpeaker? speaker;
  final String? scriptureRef;
}

class ReadingDetail {
  const ReadingDetail({
    required this.id,
    required this.kind,
    required this.title,
    required this.isPublicDomain,
    required this.parts,
    this.number,
    this.scriptureRef,
  });

  final String id;
  final ReadingKind kind;
  final int? number;
  final String title;
  final String? scriptureRef;
  final bool isPublicDomain;
  final List<ReadingPartText> parts;

  /// Whether everyone reads every part together (creeds, covenants).
  bool get readTogether =>
      parts.isNotEmpty && parts.every((p) => p.speaker == ReadingSpeaker.all);
}

class ChurchProfile {
  const ChurchProfile({
    required this.name,
    this.email,
    this.phone,
    this.whatsapp,
    this.website,
    this.tagline,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? website;

  /// A line under the church's name on Home, such as its motto. Stored on one line;
  /// Home wraps it to the screen.
  final String? tagline;
}

/// An entry of the Home screen's "Recently opened" list.
class RecentItem {
  const RecentItem({
    required this.type,
    required this.id,
    required this.title,
    this.number,
    this.preview,
    this.section,
    this.readingKind,
  });

  final ItemType type;
  final String id;
  final int? number;
  final String title;

  /// A hymn's first line, or the start of a reading.
  final String? preview;

  /// The hymn's section (null for readings).
  final Section? section;

  /// The reading's kind (null for hymns).
  final ReadingKind? readingKind;
}
