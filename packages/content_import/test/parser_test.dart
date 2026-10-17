import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

Book parse(String text) => parseSources([Source('t.txt', text)]);

List<String> describeSections(Hymn h) =>
    [for (final s in h.sections) '${s.type}:${s.number}:${s.lyrics}'];

List<String> describeParts(Reading r) =>
    [for (final p in r.parts) '${p.number}|${p.speaker}|${p.body}|${p.ref}'];

List<String> messages(Book b) => [for (final i in b.issues) i.toString()];

void main() {
  group('hymns', () {
    test('a numbered hymn keeps its labels, verses and chorus in order', () {
      final book = parse('''
SECTION Supplementary Hymns

HYMN 001
Title: Thine Is the Glory
Words: Edmond L. Budry
Music: George Frederick Handel
Translated: Richard B. Hoyle

1
Thine is the glory, risen, conqu'ring Son;

CHORUS
Endless is the vict'ry Thou o'er death hast won.

2
Lo! Jesus meets us,
risen from the tomb;
''');
      expect(messages(book), isEmpty);
      final h = book.hymns.single;
      expect(h.section, 'Supplementary Hymns');
      expect(h.number, 1);
      expect(h.title, 'Thine Is the Glory');
      expect(h.words, 'Edmond L. Budry');
      expect(h.music, 'George Frederick Handel');
      expect(h.translated, 'Richard B. Hoyle');
      expect(describeSections(h), [
        "verse:1:Thine is the glory, risen, conqu'ring Son;",
        "chorus:null:Endless is the vict'ry Thou o'er death hast won.",
        'verse:2:Lo! Jesus meets us,\nrisen from the tomb;',
      ]);
    });

    test('text before any verse number becomes one unnumbered verse', () {
      final book = parse('''
HYMN
Title: Doxology

Praise God, from whom all blessings flow;
Praise Him, all creatures here below;
''');
      expect(messages(book), isEmpty);
      final h = book.hymns.single;
      expect(h.section, 'Hymns');
      expect(h.number, isNull);
      expect(describeSections(h), [
        'verse:null:Praise God, from whom all blessings flow;\nPraise Him, all creatures here below;',
      ]);
    });

    test('TOPIC applies to the hymns after it until the next SECTION', () {
      final book = parse('''
SECTION Service Music
HYMN
Title: A
a
TOPIC Communion
HYMN
Title: B
b
SECTION Hymns
HYMN 1
Title: C
c
''');
      expect(messages(book), isEmpty);
      expect(
        [for (final h in book.hymns) '${h.title}:${h.topic}'],
        ['A:null', 'B:Communion', 'C:null'],
      );
      expect(book.sections, ['Service Music', 'Hymns']);
    });

    test('a gap in verse numbers is a warning, not an error', () {
      final book = parse('''
HYMN 7
Title: T

1
a

3
c
''');
      expect(book.hasErrors, isFalse);
      expect(messages(book), ['t.txt:1: warning: hymn 7 "T" skips verse 2']);
    });

    test('GROUP heads the hymns after it until the next SECTION', () {
      final book = parse('''
SECTION Hymns
GROUP Jesus Our Savior / His Birth
HYMN 85
Title: Joy to the World

1
Joy to the world! the Lord is come;

SECTION Supplementary Hymns
HYMN 001
Title: Blessed Assurance

1
Blessed assurance, Jesus is mine!
''');
      expect(messages(book), isEmpty);
      final birth = book.hymns[0].group!;
      expect((birth.part, birth.name), ('Jesus Our Savior', 'His Birth'));
      expect(book.hymns[1].group, isNull);
    });

    test('a GROUP without a subheading names its part; TOPIC replaces it', () {
      final book = parse('''
SECTION Hymns
GROUP The Holy Spirit
HYMN 158
Title: Holy Ghost, with Light Divine

1
Holy Ghost, with light divine,

TOPIC Communion
HYMN 191
Title: Bread of the World

1
Bread of the world in mercy broken,
''');
      expect(messages(book), isEmpty);
      final spirit = book.hymns[0].group!;
      expect((spirit.part, spirit.name), (null, 'The Holy Spirit'));
      expect(book.hymns[1].group, isNull);
      expect(book.hymns[1].topic, 'Communion');
    });

    test('a GROUP with more than one " / " is an error', () {
      final book = parse('SECTION Hymns\nGROUP A / B / C\n');
      expect(messages(book), [
        't.txt:2: error: GROUP takes "<part> / <subheading>" or just "<part>"',
      ]);
    });
  });

  group('readings', () {
    test('responsive lines keep their speaker and Ref goes to the line before',
        () {
      final book = parse('''
READING 2
Title: Creation

Leader: In the beginning God created the heaven and the earth.
People: And the earth was without form, and void.
Ref: From Genesis 1:1-2
Leader: And God said, Let there be light.
''');
      expect(messages(book), isEmpty);
      final r = book.readings.single;
      expect(r.kind, 'responsive_reading');
      expect(r.number, 2);
      expect(describeParts(r), [
        'null|leader|In the beginning God created the heaven and the earth.|null',
        'null|people|And the earth was without form, and void.|From Genesis 1:1-2',
        'null|leader|And God said, Let there be light.|null',
      ]);
    });

    test('collection items keep their number and reference; Kind sets the kind',
        () {
      final book = parse('''
READING 60
Title: Benedictions
Kind: benedictions

1. The grace of the Lord Jesus Christ be with you all. Amen.
Ref: II Corinthians 13:14

2. Now unto the King eternal be honour and glory. Amen.
Ref: I Timothy 1:17
''');
      expect(messages(book), isEmpty);
      final r = book.readings.single;
      expect(r.kind, 'benediction');
      expect(describeParts(r), [
        '1|leader|The grace of the Lord Jesus Christ be with you all. Amen.|II Corinthians 13:14',
        '2|leader|Now unto the King eternal be honour and glory. Amen.|I Timothy 1:17',
      ]);
    });

    test('a covenant keeps bullets and bold, and Read by sets every speaker',
        () {
      final book = parse('''
COVENANT
Title: The Church Covenant
Read by: All

**Having been led**, as we believe:

1. **We purpose:**
- to **walk** together in Christian love;
- to **work** for the advancement of this Church.

**AMEN!**
''');
      expect(messages(book), isEmpty);
      final r = book.readings.single;
      expect(r.kind, 'covenant');
      expect(r.number, isNull);
      expect(describeParts(r), [
        'null|all|**Having been led**, as we believe:|null',
        '1|all|**We purpose:**\n- to **walk** together in Christian love;\n- to **work** for the advancement of this Church.|null',
        'null|all|**AMEN!**|null',
      ]);
    });

    test('a creed is read by everyone unless a line says otherwise', () {
      final book = parse('''
CREED
Title: The Apostles' Creed

I believe in God the Father Almighty.
''');
      expect(
        describeParts(book.readings.single),
        ['null|all|I believe in God the Father Almighty.|null'],
      );
    });

    test('comments are ignored and Status: draft marks a draft', () {
      final book = parse('''
# a note for the proofreader
READING 2
Title: Creation
Status: draft
# INCOMPLETE: continues on the next page
Leader: In the beginning.
''');
      expect(messages(book), isEmpty);
      expect(book.readings.single.draft, isTrue);
      expect(book.readings.single.parts, hasLength(1));
    });
  });

  group('errors point at the line to fix', () {
    test('an item without a title', () {
      expect(
        messages(parse('HYMN 5\n\n1\nx\n')),
        ['t.txt:1: error: HYMN 5 has no Title'],
      );
    });

    test('a Ref before any line of the reading', () {
      expect(messages(parse('READING 1\nTitle: T\n\nRef: Psalm 1\n')), [
        't.txt:4: error: Ref: has no line before it to attach to',
        't.txt:1: error: READING 1 "T" has no lines',
      ]);
    });

    test('an unknown label', () {
      expect(
        messages(parse('HYMN 1\nTitle: T\nAuthor: X\n\n1\nx\n')),
        ['t.txt:3: error: unknown label "Author"'],
      );
    });

    test('text outside any item', () {
      expect(messages(parse('stray line\nHYMN 1\nTitle: T\n\n1\nx\n')), [
        't.txt:1: error: text outside any HYMN, READING, CREED or COVENANT',
      ]);
    });

    test('the same hymn number twice in a section, even across files', () {
      final book = parseSources([
        Source('a.txt', 'HYMN 1\nTitle: A\n\n1\na\n'),
        Source('b.txt', 'HYMN 1\nTitle: B\n\n1\nb\n'),
      ]);
      expect(
        messages(book),
        ['b.txt:1: error: Hymns 1 is already defined at a.txt:1'],
      );
    });
  });
}
