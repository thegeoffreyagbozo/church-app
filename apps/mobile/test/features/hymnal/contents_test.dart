import 'package:church_app/features/hymnal/domain/contents.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';

HymnListItem hymn(int n, {String? part, String? name}) => HymnListItem(
  id: 'h$n',
  number: n,
  title: 'Hymn $n',
  group: name == null
      ? null
      : HymnGroup(id: '${part ?? ''}/$name', name: name, part: part),
);

String describe(SectionRow row) => switch (row) {
  PartRow(:final part) => 'part ${partTitle(part)}',
  GroupRow(:final group) => 'group ${group.name}',
  HymnEntry(:final hymn) => '${hymn.number}',
};

void main() {
  final hymns = [
    hymn(1, part: 'Hymns of Worship', name: 'General'),
    hymn(2, part: 'Hymns of Worship', name: 'General'),
    hymn(34, part: 'Hymns of Worship', name: 'The Father'),
    hymn(158, name: 'The Holy Spirit'),
    hymn(159, name: 'The Holy Spirit'),
    hymn(255, part: 'The Christian Experience', name: 'Songs of Assurance'),
  ];

  test('puts a part and a subheading title before their first hymn', () {
    expect(sectionContents(hymns).rows.map(describe), [
      'part I. Hymns of Worship',
      'group General',
      '1',
      '2',
      'group The Father',
      '34',
      'part II. The Holy Spirit',
      '158',
      '159',
      'part III. The Christian Experience',
      'group Songs of Assurance',
      '255',
    ]);
  });

  test('gives parts and subheadings the range of their hymns', () {
    final parts = sectionContents(hymns).parts;

    expect(
      [for (final p in parts) rangeLabel(p.lowest, p.highest)],
      ['1-34', '158-159', '255'],
    );
    expect(parts.first.groups.map((g) => g.name), ['General', 'The Father']);
    expect(parts[1].groups, isEmpty);
  });

  test('finds the row where a part or subheading starts', () {
    final contents = sectionContents(hymns);

    expect(contents.rowOf(contents.parts[1]), 6);
    expect(contents.rowOfGroup(contents.parts.first.groups[1]), 4);
  });

  test('a section without headings is just its hymns', () {
    final contents = sectionContents([hymn(1), hymn(2)]);

    expect(contents.parts, isEmpty);
    expect(contents.rows.map(describe), ['1', '2']);
  });

  test('writes Roman numerals for the parts', () {
    expect([1, 4, 8, 9, 14].map(romanNumeral), [
      'I',
      'IV',
      'VIII',
      'IX',
      'XIV',
    ]);
  });
}
