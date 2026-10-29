/// Test fixtures for code that draws notation. Not for app code.
library;

/// The first line of Old Hundredth (public domain) in four parts with four verses, laid out
/// as the drawn-notation spec asks: two staves, soprano and alto as voices 1 and 2 on the
/// top staff, tenor and bass on the bottom staff as voices 5 and 6 (MuseScore's numbers),
/// the words on the soprano with one lyric number per verse.
String oldHundredth() {
  const durations = [2, 1, 1, 1, 1, 1, 1, 4];
  const bars = [
    [0, 1, 2],
    [3, 4, 5, 6],
    [7],
  ];
  const voices = [
    (staff: 1, voice: 1, stem: 'up', pitches: ['G4', 'G4', 'F#4', 'E4', 'D4', 'G4', 'A4', 'B4']),
    (staff: 1, voice: 2, stem: 'down', pitches: ['D4', 'D4', 'D4', 'B3', 'B3', 'D4', 'D4', 'D4']),
    (staff: 2, voice: 5, stem: 'up', pitches: ['B3', 'B3', 'A3', 'G3', 'G3', 'B3', 'F#3', 'G3']),
    (staff: 2, voice: 6, stem: 'down', pitches: ['G2', 'G2', 'D3', 'E3', 'G2', 'G3', 'D3', 'G2']),
  ];
  const verses = [
    ['All', 'peo', 'ple', 'that', 'on', 'earth', 'do', 'dwell'],
    ['The', 'Lord', 'ye', 'know', 'is', 'God', 'in', 'deed'],
    ['O', 'en', 'ter', 'then', 'his', 'gates', 'with', 'praise'],
    ['For', 'why', 'the', 'Lord', 'our', 'God', 'is', 'good'],
  ];
  // Syllables that start or end a word split across notes; every other one is 'single'.
  const split = {
    (0, 1): 'begin', (0, 2): 'end',
    (1, 6): 'begin', (1, 7): 'end',
    (2, 1): 'begin', (2, 2): 'end',
  };
  const types = {1: 'quarter', 2: 'half', 4: 'whole'};

  String pitch(String name) {
    final sharp = name.contains('#');
    final step = name[0];
    final octave = name[name.length - 1];
    return '<pitch><step>$step</step>${sharp ? '<alter>1</alter>' : ''}'
        '<octave>$octave</octave></pitch>';
  }

  String lyrics(int note) => [
    for (var v = 0; v < verses.length; v++)
      '<lyric number="${v + 1}"><syllabic>${split[(v, note)] ?? 'single'}</syllabic>'
          '<text>${verses[v][note]}</text></lyric>',
  ].join();

  final measures = StringBuffer();
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
      for (final n in bars[m]) {
        measures.write(
          '<note>${pitch(v.pitches[n])}<duration>${durations[n]}</duration>'
          '<voice>${v.voice}</voice><type>${types[durations[n]]}</type>'
          '<stem>${v.stem}</stem><staff>${v.staff}</staff>'
          '${v.voice == 1 ? lyrics(n) : ''}</note>',
        );
      }
      if (i < voices.length - 1) measures.write('<backup><duration>4</duration></backup>');
    }
    measures.write('</measure>');
  }

  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<score-partwise version="4.0"><part-list><score-part id="P1">'
      '<part-name>Choir</part-name></score-part></part-list>'
      '<part id="P1">$measures</part></score-partwise>';
}
