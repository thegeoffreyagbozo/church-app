import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' SIL Open Font License texts to the Licences page.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Literata', 'literata'),
      ('Fraunces', 'fraunces'),
      ('Inter', 'inter'),
      ('Atkinson Hyperlegible', 'atkinsonhyperlegible'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/licenses/$file.txt'));
    }
  });
}
