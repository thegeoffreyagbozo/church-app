import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _folder = 'packages/notation/assets/licences';

/// Adds Verovio's LGPL-3.0 (with the GPL-3.0 it builds on, and where its source is)
/// and the music and text fonts' SIL Open Font License texts to the Licences page.
void registerNotationLicences() {
  LicenseRegistry.addLicense(() async* {
    final lgpl = await rootBundle.loadString('$_folder/verovio-lgpl-3.0.txt');
    final gpl = await rootBundle.loadString('$_folder/verovio-gpl-3.0.txt');
    yield LicenseEntryWithLineBreaks(
      ['Verovio'],
      'Verovio 6.3.0, built unchanged from '
      'https://github.com/rism-digital/verovio/tree/version-6.3.0 and linked as '
      'a shared library (libverovio.so).\n\n$lgpl\n\n$gpl',
    );
    for (final (font, file) in const [
      ('Bravura', 'bravura'),
      ('Leipzig', 'leipzig'),
      ('Leland', 'leland'),
      ('Tinos', 'tinos'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('$_folder/$file.txt'));
    }
  });
}
