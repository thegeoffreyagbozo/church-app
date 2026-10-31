/// Draws a hymn's MusicXML on the phone with Verovio.
library;

export 'src/engine.dart' show NotationEngine;
export 'src/licences.dart' show registerNotationLicences;
export 'src/options.dart' show defaultScale, maxScale, minScale;
export 'src/parts.dart' show Part, fadedOpacity;
export 'src/verovio.dart' show NotationException;
export 'src/verses.dart' show verseCount;
