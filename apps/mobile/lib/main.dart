import 'package:flutter/widgets.dart';

import 'core/theme/font_licences.dart';
import 'startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();
  runApp(const StartupApp());
}
