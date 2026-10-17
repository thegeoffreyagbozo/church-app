import 'dart:math' as math;

import 'package:content_db/content_db.dart';

/// The lowest and highest hymn numbers of a part or subheading in the app.
mixin NumberRange {
  int? lowest;
  int? highest;

  void include(int? number) {
    if (number == null) return;
    lowest = lowest == null ? number : math.min(lowest!, number);
    highest = highest == null ? number : math.max(highest!, number);
  }
}

/// A subheading of the book's contents, such as "His Birth".
class ContentsGroup with NumberRange {
  ContentsGroup(this.name);
  final String name;
}

/// A part of the book's contents, such as "Jesus Our Savior", numbered from 1 in book
/// order; [groups] is empty when the part has no subheadings ("The Holy Spirit").
class ContentsPart with NumberRange {
  ContentsPart(this.numeral, this.name);
  final int numeral;
  final String name;
  final List<ContentsGroup> groups = [];
}

/// A row of a section list laid out like the book's contents.
sealed class SectionRow {
  const SectionRow();
}

final class PartRow extends SectionRow {
  const PartRow(this.part);
  final ContentsPart part;
}

final class GroupRow extends SectionRow {
  const GroupRow(this.group);
  final ContentsGroup group;
}

final class HymnEntry extends SectionRow {
  const HymnEntry(this.hymn);
  final HymnListItem hymn;
}

/// A section's hymns under the part and subheading titles of the book's contents.
class SectionContents {
  const SectionContents._(this.rows, this.parts);

  /// The hymns in list order, with a title row before the first hymn of each part and
  /// subheading.
  final List<SectionRow> rows;

  /// The parts in book order; empty when the section has no contents headings.
  final List<ContentsPart> parts;

  /// The row where [part] starts.
  int rowOf(ContentsPart part) =>
      rows.indexWhere((r) => r is PartRow && identical(r.part, part));

  /// The row where [group] starts.
  int rowOfGroup(ContentsGroup group) =>
      rows.indexWhere((r) => r is GroupRow && identical(r.group, group));
}

/// Lays [hymns] (in list order) out under the titles of their contents headings.
/// Hymns without a heading are listed as they are.
SectionContents sectionContents(List<HymnListItem> hymns) {
  final parts = <String, ContentsPart>{};
  final groups = <String, ContentsGroup>{};
  final rows = <SectionRow>[];
  String? lastPart;
  String? lastGroup;
  for (final hymn in hymns) {
    final heading = hymn.group;
    if (heading != null) {
      final name = heading.partName;
      final part = parts.putIfAbsent(
        name,
        () => ContentsPart(parts.length + 1, name),
      )..include(hymn.number);
      if (name != lastPart) {
        rows.add(PartRow(part));
        lastPart = name;
        lastGroup = null;
      }
      if (heading.part != null) {
        final group = groups.putIfAbsent(heading.id, () {
          final group = ContentsGroup(heading.name);
          part.groups.add(group);
          return group;
        })..include(hymn.number);
        if (heading.id != lastGroup) {
          rows.add(GroupRow(group));
          lastGroup = heading.id;
        }
      }
    }
    rows.add(HymnEntry(hymn));
  }
  return SectionContents._(rows, parts.values.toList());
}

/// "II. Jesus Our Savior".
String partTitle(ContentsPart part) =>
    '${romanNumeral(part.numeral)}. ${part.name}';

/// "85-101", "521" for a single hymn, or nothing when the hymns have no numbers.
String rangeLabel(int? lowest, int? highest) {
  if (lowest == null || highest == null) return '';
  return lowest == highest ? '$lowest' : '$lowest-$highest';
}

String romanNumeral(int number) {
  const letters = [
    (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), //
    (5, 'V'), (4, 'IV'), (1, 'I'),
  ];
  final out = StringBuffer();
  var rest = number;
  for (final (value, letter) in letters) {
    while (rest >= value) {
      out.write(letter);
      rest -= value;
    }
  }
  return out.toString();
}
