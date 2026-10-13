/// A book, chapter and optional verse typed into search, such as "Psalm 23" or
/// "II Cor 13:14".
class BibleRef {
  const BibleRef(this.book, this.chapter, [this.verse]);

  /// 1 for Genesis to 66 for Revelation.
  final int book;
  final int chapter;
  final int? verse;

  @override
  bool operator ==(Object other) =>
      other is BibleRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);

  @override
  String toString() =>
      'BibleRef($book, $chapter${verse == null ? '' : ', $verse'})';
}

/// A passage the book cites: from a chapter (and verse) to a chapter (and verse).
/// A whole chapter has no verses.
class ScriptureSpan {
  const ScriptureSpan(
    this.book,
    this.fromChapter,
    this.fromVerse,
    this.toChapter,
    this.toVerse,
  );

  final int book;
  final int fromChapter;
  final int? fromVerse;
  final int toChapter;
  final int? toVerse;

  /// Whether this passage includes [ref] (a whole chapter when [ref] has no verse).
  bool covers(BibleRef ref) {
    if (ref.book != book) return false;
    if (ref.chapter < fromChapter || ref.chapter > toChapter) return false;
    final verse = ref.verse;
    if (verse == null) return true;
    if (ref.chapter == fromChapter && fromVerse != null && verse < fromVerse!) {
      return false;
    }
    if (ref.chapter == toChapter && toVerse != null && verse > toVerse!) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptureSpan &&
      other.book == book &&
      other.fromChapter == fromChapter &&
      other.fromVerse == fromVerse &&
      other.toChapter == toChapter &&
      other.toVerse == toVerse;

  @override
  int get hashCode =>
      Object.hash(book, fromChapter, fromVerse, toChapter, toVerse);

  @override
  String toString() =>
      'ScriptureSpan($book, $fromChapter:$fromVerse-$toChapter:$toVerse)';
}

/// The 66 books with the short forms people type. Numbered books use "1 ", "2 ", "3 ".
const _books = <List<String>>[
  ['genesis', 'gen', 'gn'],
  ['exodus', 'ex', 'exod'],
  ['leviticus', 'lev'],
  ['numbers', 'num'],
  ['deuteronomy', 'deut', 'dt'],
  ['joshua', 'josh'],
  ['judges', 'judg'],
  ['ruth'],
  ['1 samuel', '1 sam'],
  ['2 samuel', '2 sam'],
  ['1 kings', '1 kgs'],
  ['2 kings', '2 kgs'],
  ['1 chronicles', '1 chron', '1 chr'],
  ['2 chronicles', '2 chron', '2 chr'],
  ['ezra'],
  ['nehemiah', 'neh'],
  ['esther', 'esth'],
  ['job'],
  ['psalms', 'psalm', 'ps', 'psa', 'pss'],
  ['proverbs', 'prov', 'pr'],
  ['ecclesiastes', 'eccl', 'eccles'],
  ['song of solomon', 'song of songs', 'song', 'sos'],
  ['isaiah', 'isa'],
  ['jeremiah', 'jer'],
  ['lamentations', 'lam'],
  ['ezekiel', 'ezek', 'eze'],
  ['daniel', 'dan'],
  ['hosea', 'hos'],
  ['joel'],
  ['amos'],
  ['obadiah', 'obad'],
  ['jonah', 'jon'],
  ['micah', 'mic'],
  ['nahum', 'nah'],
  ['habakkuk', 'hab'],
  ['zephaniah', 'zeph'],
  ['haggai', 'hag'],
  ['zechariah', 'zech'],
  ['malachi', 'mal'],
  ['matthew', 'matt', 'mt'],
  ['mark', 'mk'],
  ['luke', 'lk'],
  ['john', 'jn', 'jhn'],
  ['acts'],
  ['romans', 'rom'],
  ['1 corinthians', '1 cor'],
  ['2 corinthians', '2 cor'],
  ['galatians', 'gal'],
  ['ephesians', 'eph'],
  ['philippians', 'phil', 'php'],
  ['colossians', 'col'],
  ['1 thessalonians', '1 thess', '1 th'],
  ['2 thessalonians', '2 thess', '2 th'],
  ['1 timothy', '1 tim'],
  ['2 timothy', '2 tim'],
  ['titus', 'tit'],
  ['philemon', 'philem', 'phlm'],
  ['hebrews', 'heb'],
  ['james', 'jas'],
  ['1 peter', '1 pet'],
  ['2 peter', '2 pet'],
  ['1 john', '1 jn'],
  ['2 john', '2 jn'],
  ['3 john', '3 jn'],
  ['jude'],
  ['revelation', 'rev', 'revelations'],
];

const _ordinals = {
  'first': '1',
  'second': '2',
  'third': '3',
  '1st': '1',
  '2nd': '2',
  '3rd': '3',
  'i': '1',
  'ii': '2',
  'iii': '3',
  '1': '1',
  '2': '2',
  '3': '3',
};

// Roman and spelled-out ordinals need a space after them ("ii cor"), digits don't
// ("2cor"), so "isaiah" is never read as "i saiah".
final _bookName = RegExp(
  r'^(?:(first|second|third|1st|2nd|3rd|iii|ii|i)\s+|([123])\s*)?'
  r'([a-z]+(?:\s+of\s+[a-z]+)?)\.?\s*',
);
final _queryRest = RegExp(r'^(\d{1,3})(?:\s*[:.]\s*(\d{1,3}))?$');
final _item = RegExp(r'^(\d+)(?:[:.](\d+))?(?:\s*-\s*(\d+)(?:[:.](\d+))?)?$');

/// Which book [ordinal] and [name] mean: an exact name or short form, else the only
/// book whose name starts with at least three typed letters. Null when unsure.
int? _book(String? ordinal, String name) {
  final key = ordinal == null ? name : '$ordinal $name';
  for (final (i, names) in _books.indexed) {
    if (names.contains(key)) return i + 1;
  }
  if (name.length < 3) return null;
  final starts = [
    for (final (i, names) in _books.indexed)
      if (names.first.startsWith(key)) i + 1,
  ];
  return starts.length == 1 ? starts.single : null;
}

/// Splits a leading book name off [text]: its number and the rest of the text.
(int, String)? _splitBook(String text) {
  final match = _bookName.firstMatch(text);
  if (match == null) return null;
  final ordinal = _ordinals[match[1] ?? match[2]];
  final book = _book(ordinal, match[3]!.replaceAll(RegExp(r'\s+'), ' '));
  if (book == null) return null;
  return (book, text.substring(match.end).trim());
}

String _normalize(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Reads a reference typed into search ("Psalm 23", "ii cor 13:14", "1cor 13"), or
/// null when [input] isn't one.
BibleRef? parseBibleRef(String input) {
  final split = _splitBook(_normalize(input));
  if (split == null) return null;
  final (book, rest) = split;
  final numbers = _queryRest.firstMatch(rest);
  if (numbers == null) return null;
  final verse = numbers[2];
  return BibleRef(
    book,
    int.parse(numbers[1]!),
    verse == null ? null : int.parse(verse),
  );
}

/// The passages in a reference as printed in the book, such as
/// "Psalm 34:3; 66:1-4; 67:3-5", "II Corinthians 13:14" or "Romans 12:1-2, 9-10".
/// Parts it can't read are skipped.
List<ScriptureSpan> parseScriptureRefs(String text) {
  final spans = <ScriptureSpan>[];
  int? book;
  for (final segment in _normalize(text).split(';')) {
    var rest = segment.trim();
    final split = _splitBook(rest);
    if (split != null) (book, rest) = split;
    if (book == null) continue;
    int? chapter;
    for (final item in rest.split(',')) {
      final m = _item.firstMatch(item.trim());
      if (m == null) continue;
      final a = int.parse(m[1]!);
      final b = m[2] == null ? null : int.parse(m[2]!);
      final c = m[3] == null ? null : int.parse(m[3]!);
      final d = m[4] == null ? null : int.parse(m[4]!);
      if (b != null) {
        // 13:14, 6:24-26 or 3:16-4:2
        final toChapter = d == null ? a : c!;
        spans.add(ScriptureSpan(book, a, b, toChapter, d ?? c ?? b));
        chapter = toChapter;
      } else if (chapter != null && d == null) {
        // ", 9-10" after "12:1-2": more verses of the same chapter
        spans.add(ScriptureSpan(book, chapter, a, chapter, c ?? a));
      } else {
        // 23 or 3-4: whole chapters; 3-4:2 ends at a verse
        spans.add(ScriptureSpan(book, a, null, c ?? a, d));
        chapter = d == null ? null : c;
      }
    }
  }
  return spans;
}
