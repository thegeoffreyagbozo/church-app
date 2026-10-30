/// Test fixtures for code that draws notation. Not for app code.
library;

/// The first two lines of Old Hundredth (public domain) in four parts with four verses,
/// laid out as the drawn-notation spec asks: two staves, soprano and alto as voices 1
/// and 2 on the top staff, tenor and bass on the bottom staff as voices 5 and 6
/// (MuseScore's numbers), the words on the soprano with one lyric number per verse. It
/// also carries what real hymns have and a single line doesn't: a tie across a barline
/// (alto), a slur (bass), a rest in every voice and a final double barline.
///
/// A note is written as pitch and octave (`F#4`), `R` for a rest, a trailing `~` to
/// start a tie and a leading `~` to end one, `(` and `)` to start and end a slur.
String oldHundredth() {
  const bars = [
    [2, 1, 1],
    [1, 1, 1, 1],
    [4],
    [2, 1, 1],
    [1, 1, 1, 1],
    [2, 2],
  ];
  const voices = [
    (
      staff: 1,
      voice: 1,
      stem: 'up',
      notes: 'G4 G4 F#4 E4 D4 G4 A4 B4 B4 B4 B4 A4 G4 C5 B4 A4 R',
    ),
    (
      staff: 1,
      voice: 2,
      stem: 'down',
      notes: 'D4 D4 D4 B3 B3 D4 D4 D4~ ~D4 D4 G4 F#4 D4 E4 D4 D4 R',
    ),
    (
      staff: 2,
      voice: 5,
      stem: 'up',
      notes: 'B3 B3 A3 G3 G3 B3 F#3 G3 D4 D4 D4 D4 B3 C4 D4 F#3 R',
    ),
    (
      staff: 2,
      voice: 6,
      stem: 'down',
      notes: 'G2 G2 D3 E3 G2 G3 D3 G2 G3 G3 G3 D3 G3( A3) G3 D3 R',
    ),
  ];
  const verses = [
    'All peo ple that on earth do dwell Sing to the Lord with cheer ful voice',
    'The Lord ye know is God in deed With out our aid he did us make',
    'O en ter then his gates with praise Ap proach with joy his courts un to',
    'For why the Lord our God is good His mer cy is for ev er sure',
  ];
  // The first syllable of each word split across two notes; the next one ends it.
  const splitStarts = [
    {1, 13},
    {6, 8},
    {1, 8, 14},
    {9, 13},
  ];
  const types = {1: 'quarter', 2: 'half', 4: 'whole'};

  String syllabic(int verse, int note) {
    if (splitStarts[verse].contains(note)) return 'begin';
    if (splitStarts[verse].contains(note - 1)) return 'end';
    return 'single';
  }

  String lyrics(int note) => [
    for (var v = 0; v < verses.length; v++)
      '<lyric number="${v + 1}"><syllabic>${syllabic(v, note)}</syllabic>'
          '<text>${verses[v].split(' ')[note]}</text></lyric>',
  ].join();

  String note(
    String token,
    int duration,
    ({int staff, int voice, String stem}) v,
    int sung,
  ) {
    final tieStop = token.startsWith('~');
    final tieStart = token.endsWith('~');
    final slurStart = token.endsWith('(');
    final slurStop = token.endsWith(')');
    final name = token.replaceAll(RegExp(r'[~()]'), '');
    final type = '<type>${types[duration]}</type>';
    if (name == 'R') {
      return '<note><rest/><duration>$duration</duration><voice>${v.voice}</voice>'
          '$type<staff>${v.staff}</staff></note>';
    }
    final alter = name.contains('#') ? '<alter>1</alter>' : '';
    final pitch =
        '<pitch><step>${name[0]}</step>$alter'
        '<octave>${name[name.length - 1]}</octave></pitch>';
    final ties = [
      if (tieStop) '<tie type="stop"/>',
      if (tieStart) '<tie type="start"/>',
    ].join();
    final notations = [
      if (tieStop) '<tied type="stop"/>',
      if (tieStart) '<tied type="start"/>',
      if (slurStart) '<slur type="start" number="1"/>',
      if (slurStop) '<slur type="stop" number="1"/>',
    ].join();
    return '<note>$pitch<duration>$duration</duration>$ties<voice>${v.voice}</voice>'
        '$type<stem>${v.stem}</stem><staff>${v.staff}</staff>'
        '${notations.isEmpty ? '' : '<notations>$notations</notations>'}'
        '${v.voice == 1 ? lyrics(sung) : ''}</note>';
  }

  final measures = StringBuffer();
  final position = [for (final _ in voices) 0];
  for (var m = 0; m < bars.length; m++) {
    measures.write('<measure number="${m + 1}">');
    if (m == 0) {
      measures.write(
        '<attributes><divisions>1</divisions><key><fifths>1</fifths></key>'
        '<time><beats>4</beats><beat-type>4</beat-type></time><staves>2</staves>'
        '<clef number="1"><sign>G</sign><line>2</line></clef>'
        '<clef number="2"><sign>F</sign><line>4</line></clef></attributes>',
      );
    }
    for (var i = 0; i < voices.length; i++) {
      final v = voices[i];
      final tokens = v.notes.split(' ');
      for (final duration in bars[m]) {
        measures.write(
          note(tokens[position[i]], duration, (
            staff: v.staff,
            voice: v.voice,
            stem: v.stem,
          ), position[i]),
        );
        position[i]++;
      }
      if (i < voices.length - 1) {
        measures.write('<backup><duration>4</duration></backup>');
      }
    }
    if (m == bars.length - 1) {
      measures.write(
        '<barline location="right"><bar-style>light-heavy</bar-style></barline>',
      );
    }
    measures.write('</measure>');
  }

  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<score-partwise version="4.0"><part-list><score-part id="P1">'
      '<part-name>Choir</part-name></score-part></part-list>'
      '<part id="P1">$measures</part></score-partwise>';
}
