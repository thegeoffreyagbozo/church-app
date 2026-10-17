import 'model.dart';

final _section = RegExp(r'^SECTION\s+(.+)$');
final _topic = RegExp(r'^TOPIC\s+(.+)$');
final _group = RegExp(r'^GROUP\s+(.+)$');
final _hymn = RegExp(r'^HYMN(?:\s+(\d+))?$');
final _reading = RegExp(r'^READING\s+(\d+)$');
final _label = RegExp(r'^([A-Za-z][A-Za-z ]*?):\s*(.*)$');
final _verse = RegExp(r'^(\d+)$');
final _chorus = RegExp(r'^(CHORUS|REFRAIN)$', caseSensitive: false);
final _speakerLine = RegExp(r'^(Leader|People|All):\s*(.+)$');
final _numberedItem = RegExp(r'^(\d+)\.\s+(.+)$');
final _ref = RegExp(r'^Ref:\s*(.+)$');
final _bullet = RegExp(r'^- ');

const _hymnLabels = {
  'Title', 'Tune', 'Words', 'Music', 'Arranged', 'Translated', 'Scripture', //
  'Also sung to', 'Meter', 'Key', 'Copyright', 'Status',
};
const _readingLabels = {
  'Title',
  'Scripture',
  'Kind',
  'Read by',
  'Copyright',
  'Status',
};
const _kinds = {
  'responsive reading': 'responsive_reading',
  'call to worship': 'call_to_worship',
  'calls to worship': 'call_to_worship',
  'benediction': 'benediction',
  'benedictions': 'benediction',
  'creed': 'creed',
  'covenant': 'covenant',
};
const _speakers = {'leader': 'leader', 'people': 'people', 'all': 'all'};

/// Who reads a part that names no reader and has no "Read by:" label.
const _defaultSpeaker = {
  'call_to_worship': 'leader',
  'benediction': 'leader',
  'creed': 'all',
  'covenant': 'all',
};

/// Parses transcribed hymn-book [sources] (see the format reminder in the batch files).
///
/// Hymns before any SECTION line belong to [defaultSection]. Problems are collected in
/// [Book.issues] with the file and line to fix; items with errors are left out.
Book parseSources(List<Source> sources, {String defaultSection = 'Hymns'}) {
  final book = Book();
  final seen = <String, String>{};
  for (final source in sources) {
    _Parser(book, source, defaultSection, seen).run();
  }
  return book;
}

class _Parser {
  _Parser(this.book, this.source, this.defaultSection, this.seen);

  final Book book;
  final Source source;
  final String defaultSection;

  /// Item keys already defined (across all sources) mapped to "file:line".
  final Map<String, String> seen;

  String? section;
  String? topic;
  Grouping? group;
  Hymn? hymn;
  Reading? reading;
  bool inLabels = false;

  /// Whether plain text continues the current reading part (no blank line since).
  bool partOpen = false;

  void run() {
    final lines = source.text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      _line(lines[i].trim(), i + 1);
    }
    _finish();
  }

  void _error(int line, String message) =>
      book.issues.add(Issue(source.name, line, message));

  void _warn(int line, String message) =>
      book.issues.add(Issue(source.name, line, message, isError: false));

  void _line(String t, int n) {
    if (t.startsWith('#')) return;
    if (t.isEmpty) {
      inLabels = false;
      partOpen = false;
      return;
    }
    if (_header(t, n)) return;
    if (hymn == null && reading == null) {
      _error(n, 'text outside any HYMN, READING, CREED or COVENANT');
      return;
    }
    if (inLabels) {
      final label = _label.firstMatch(t);
      if (label != null && !_isBodyLine(t)) {
        _setLabel(label[1]!, label[2]!.trim(), n);
        return;
      }
      inLabels = false;
    }
    if (hymn != null) {
      _hymnLine(t);
    } else {
      _readingLine(t, n);
    }
  }

  bool _header(String t, int n) {
    final sectionMatch = _section.firstMatch(t);
    if (sectionMatch != null) {
      _finish();
      section = sectionMatch[1]!.trim();
      topic = null;
      group = null;
      return true;
    }
    final topicMatch = _topic.firstMatch(t);
    if (topicMatch != null) {
      _finish();
      topic = topicMatch[1]!.trim();
      group = null;
      return true;
    }
    final groupMatch = _group.firstMatch(t);
    if (groupMatch != null) {
      _finish();
      final names = groupMatch[1]!.split(' / ').map((s) => s.trim()).toList();
      if (names.length > 2 || names.any((s) => s.isEmpty)) {
        _error(n, 'GROUP takes "<part> / <subheading>" or just "<part>"');
        return true;
      }
      group = names.length == 2
          ? Grouping(names[0], names[1])
          : Grouping(null, names[0]);
      topic = null;
      return true;
    }
    final hymnMatch = _hymn.firstMatch(t);
    if (hymnMatch != null) {
      _finish();
      final number = hymnMatch[1] == null ? null : int.parse(hymnMatch[1]!);
      hymn = Hymn(
        section ?? defaultSection,
        topic,
        number,
        source.name,
        n,
        group: group,
      );
      inLabels = true;
      return true;
    }
    final readingMatch = _reading.firstMatch(t);
    if (readingMatch != null || t == 'CREED' || t == 'COVENANT') {
      _finish();
      reading = readingMatch != null
          ? Reading(
              'responsive_reading',
              int.parse(readingMatch[1]!),
              source.name,
              n,
            )
          : Reading(t.toLowerCase(), null, source.name, n);
      inLabels = true;
      return true;
    }
    return false;
  }

  bool _isBodyLine(String t) => hymn != null
      ? _verse.hasMatch(t) || _chorus.hasMatch(t)
      : _speakerLine.hasMatch(t) ||
          _numberedItem.hasMatch(t) ||
          _ref.hasMatch(t);

  void _setLabel(String name, String value, int n) {
    if (!(hymn != null ? _hymnLabels : _readingLabels).contains(name)) {
      _error(n, 'unknown label "$name"');
      return;
    }
    if (name == 'Status') {
      if (value.toLowerCase() != 'draft') {
        _error(n, 'Status can only be "draft"');
      } else if (hymn != null) {
        hymn!.draft = true;
      } else {
        reading!.draft = true;
      }
      return;
    }
    final h = hymn;
    if (h != null) {
      switch (name) {
        case 'Title':
          h.title = value;
        case 'Tune':
          h.tune = value;
        case 'Words':
          h.words = value;
        case 'Music':
          h.music = value;
        case 'Arranged':
          h.arranged = value;
        case 'Translated':
          h.translated = value;
        case 'Scripture':
          h.scripture = value;
        case 'Also sung to':
          h.alsoSungTo = value;
        case 'Meter':
          h.meter = value;
        case 'Key':
          h.musicKey = value;
        case 'Copyright':
          h.copyright = value;
      }
      return;
    }
    final r = reading!;
    switch (name) {
      case 'Title':
        r.title = value;
      case 'Scripture':
        r.scripture = value;
      case 'Copyright':
        r.copyright = value;
      case 'Kind':
        final kind = _kinds[value.toLowerCase()];
        if (kind == null) {
          _error(n, 'unknown Kind "$value"');
        } else {
          r.kind = kind;
        }
      case 'Read by':
        final speaker = _speakers[value.toLowerCase()];
        if (speaker == null) {
          _error(n, 'Read by must be Leader, People or All');
        } else {
          r.readBy = speaker;
        }
    }
  }

  void _hymnLine(String t) {
    final h = hymn!;
    final verse = _verse.firstMatch(t);
    if (verse != null) {
      h.sections.add(HymnSection('verse', int.parse(verse[1]!), ''));
      return;
    }
    final chorus = _chorus.firstMatch(t);
    if (chorus != null) {
      h.sections.add(HymnSection(chorus[1]!.toLowerCase(), null, ''));
      return;
    }
    if (h.sections.isEmpty) h.sections.add(HymnSection('verse', null, ''));
    final s = h.sections.last;
    s.lyrics = s.lyrics.isEmpty ? t : '${s.lyrics}\n$t';
  }

  void _readingLine(String t, int n) {
    final r = reading!;
    final speaker = _speakerLine.firstMatch(t);
    if (speaker != null) {
      _addPart(null, _speakers[speaker[1]!.toLowerCase()], speaker[2]!);
      return;
    }
    final item = _numberedItem.firstMatch(t);
    if (item != null) {
      _addPart(int.parse(item[1]!), null, item[2]!);
      return;
    }
    final ref = _ref.firstMatch(t);
    if (ref != null) {
      if (r.parts.isEmpty) {
        _error(n, 'Ref: has no line before it to attach to');
      } else {
        r.parts.last.ref = ref[1]!.trim();
        partOpen = false;
      }
      return;
    }
    // Bullets and wrapped lines continue the part above; other text starts a paragraph.
    if (r.parts.isNotEmpty && (partOpen || _bullet.hasMatch(t))) {
      r.parts.last.body = '${r.parts.last.body}\n$t';
      partOpen = true;
      return;
    }
    _addPart(null, null, t);
  }

  void _addPart(int? number, String? speaker, String body) {
    reading!.parts.add(ReadingPart(number, speaker, body.trim()));
    partOpen = true;
  }

  void _finish() {
    final h = hymn;
    final r = reading;
    hymn = null;
    reading = null;
    inLabels = false;
    partOpen = false;
    if (h != null) _finishHymn(h);
    if (r != null) _finishReading(r);
  }

  void _finishHymn(Hymn h) {
    final header = h.number == null ? 'HYMN' : 'HYMN ${h.number}';
    final title = h.title;
    if (title == null || title.isEmpty) {
      _error(h.line, '$header has no Title');
      return;
    }
    if (h.sections.every((s) => s.lyrics.isEmpty)) {
      _error(h.line, '$header "$title" has no words');
      return;
    }
    final verses = {
      for (final s in h.sections)
        if (s.type == 'verse' && s.number != null) s.number!,
    };
    final last = verses.fold(0, (a, b) => a > b ? a : b);
    final label = h.number == null ? 'hymn' : 'hymn ${h.number}';
    for (var v = 1; v < last; v++) {
      if (!verses.contains(v)) _warn(h.line, '$label "$title" skips verse $v');
    }
    final name = '${h.section} ${h.number ?? '"$title"'}';
    if (!_claim(
      'hymn/${h.section}/${h.number ?? title.toLowerCase()}',
      name,
      h.line,
    )) {
      return;
    }
    if (!book.sections.contains(h.section)) book.sections.add(h.section);
    book.hymns.add(h);
  }

  void _finishReading(Reading r) {
    final header =
        r.number == null ? r.kind.toUpperCase() : 'READING ${r.number}';
    final title = r.title;
    if (title == null || title.isEmpty) {
      _error(r.line, '$header has no Title');
      return;
    }
    if (r.parts.isEmpty) {
      _error(r.line, '$header "$title" has no lines');
      return;
    }
    final fallback = r.readBy ?? _defaultSpeaker[r.kind];
    for (final p in r.parts) {
      p.speaker ??= fallback;
    }
    final key = 'reading/${r.number ?? '${r.kind}/${title.toLowerCase()}'}';
    if (!_claim(key, header, r.line)) return;
    book.readings.add(r);
  }

  /// Records [key] as defined here; reports an error if it was already defined.
  bool _claim(String key, String name, int line) {
    final previous = seen[key];
    if (previous != null) {
      _error(line, '$name is already defined at $previous');
      return false;
    }
    seen[key] = '${source.name}:$line';
    return true;
  }
}
