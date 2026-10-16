import 'package:flutter/widgets.dart';

import 'core/theme/font_licences.dart';
import 'startup.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();
  // Keep the native splash up until the hymn book is open, so it leads straight to Home
  // instead of an empty screen.
  binding.deferFirstFrame();
  runApp(StartupApp(onReady: binding.allowFirstFrame));
}
