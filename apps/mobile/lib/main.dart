import 'package:flutter/widgets.dart';
import 'package:notation/notation.dart';

import 'core/theme/font_licences.dart';
import 'startup.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  registerLicences();
  // Keep the native splash up until the hymn book is open, so it leads straight to Home
  // instead of an empty screen.
  binding.deferFirstFrame();
  runApp(StartupApp(onReady: binding.allowFirstFrame));
}

/// Adds the bundled fonts' and the notation engine's licences to the Licences page.
void registerLicences() {
  registerFontLicences();
  registerNotationLicences();
}
