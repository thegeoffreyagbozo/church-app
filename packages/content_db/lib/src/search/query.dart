import '../models.dart';
import 'scripture.dart';

/// What someone typed into search, in the order the rules are tried (spec section 4).
sealed class SearchInput {
  const SearchInput();
}

/// Nothing to search for.
final class EmptyInput extends SearchInput {
  const EmptyInput();
}

/// Only digits, such as "268": that number in the default section first.
final class NumberInput extends SearchInput {
  const NumberInput(this.number);
  final int number;
}

/// A section and a number, such as "S2", "s 2" or "hymn 268".
final class SectionNumberInput extends SearchInput {
  const SectionNumberInput(this.section, this.number);
  final Section section;
  final int number;
}

/// A reading number, such as "R5" or "reading 5".
final class ReadingNumberInput extends SearchInput {
  const ReadingNumberInput(this.number);
  final int number;
}

/// A scripture reference, such as "Psalm 23"; its words are searched as well.
final class ScriptureInput extends SearchInput {
  const ScriptureInput(this.ref, this.text);
  final BibleRef ref;
  final String text;
}

/// Anything else: words matched at the start of words in the book.
final class WordsInput extends SearchInput {
  const WordsInput(this.text);
  final String text;
}

final _number = RegExp(r'^#?\s*(\d{1,4})$');
final _wordAndNumber = RegExp(
  r'^([a-z]+)\.?\s*(?:(?:no|number)\.?\s*|#\s*)?(\d{1,4})$',
);
final _space = RegExp(r'\s+');
final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// One-letter shortcuts: the first letter of each numbered section's name when no other
/// numbered section starts with it. "r" is kept for readings.
Map<String, Section> sectionLetters(List<Section> sections) {
  final numbered = sections.where((s) => s.isNumbered).toList();
  final firstLetters = [for (final s in numbered) s.name.toLowerCase()[0]];
  return {
    for (final (i, s) in numbered.indexed)
      if (firstLetters[i] != 'r' &&
          firstLetters.where((l) => l == firstLetters[i]).length == 1)
        firstLetters[i]: s,
  };
}

/// Works out what [raw] asks for, given the book's [sections].
SearchInput interpretQuery(String raw, List<Section> sections) {
  final text = raw.toLowerCase().replaceAll(_space, ' ').trim();
  if (text.isEmpty) return const EmptyInput();

  final number = _number.firstMatch(text);
  if (number != null) return NumberInput(int.parse(number[1]!));

  final wordAndNumber = _wordAndNumber.firstMatch(text);
  if (wordAndNumber != null) {
    final word = wordAndNumber[1]!;
    final n = int.parse(wordAndNumber[2]!);
    if (word == 'r' || (word.length >= 2 && 'readings'.startsWith(word))) {
      return ReadingNumberInput(n);
    }
    final section = word.length == 1
        ? sectionLetters(sections)[word]
        : _sectionStartingWith(word, sections);
    if (section != null) return SectionNumberInput(section, n);
  }

  final ref = parseBibleRef(text);
  if (ref != null) return ScriptureInput(ref, text);

  return WordsInput(text);
}

/// The only numbered section whose name starts with [word] ("hymn", "supp").
Section? _sectionStartingWith(String word, List<Section> sections) {
  final matches = [
    for (final s in sections)
      if (s.isNumbered && s.name.toLowerCase().startsWith(word)) s,
  ];
  return matches.length == 1 ? matches.single : null;
}

/// The full-text query matching the beginning of every word in [text], so "How fi"
/// finds "How Firm"; null when [text] has no words.
String? ftsMatchQuery(String text) {
  final words = _word.allMatches(text.toLowerCase()).map((m) => m[0]!);
  if (words.isEmpty) return null;
  return words.map((w) => '"$w"*').join(' ');
}
