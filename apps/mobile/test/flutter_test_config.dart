import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so widget tests and golden images use the real typefaces.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Each test opens its own in-memory database and closes it in tearDown.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const fonts = {
    'Literata': [
      'Literata-Regular',
      'Literata-Italic',
      'Literata-SemiBold',
      'Literata-Bold',
    ],
    'Fraunces': ['Fraunces-Regular', 'Fraunces-SemiBold'],
    'Inter': ['Inter-Regular', 'Inter-SemiBold'],
    'AtkinsonHyperlegible': [
      'AtkinsonHyperlegible-Regular',
      'AtkinsonHyperlegible-Italic',
      'AtkinsonHyperlegible-Bold',
    ],
  };
  for (final MapEntry(key: family, value: files) in fonts.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
  await (FontLoader('packages/lucide_flutter/LucideIcons')
        ..addFont(rootBundle.load('packages/lucide_flutter/assets/lucide.ttf')))
      .load();
  await testMain();
}
