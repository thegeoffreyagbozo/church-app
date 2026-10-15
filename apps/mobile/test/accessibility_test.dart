import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

/// Tap targets, labels and text contrast on every screen, in both themes (spec
/// section 7). A tall screen keeps text out from under the translucent tab bar, where
/// the contrast check would measure the bar instead of the page.
void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  for (final theme in [ReadingTheme.paper, ReadingTheme.night]) {
    for (final location in [
      '/',
      '/section/section-hymns',
      '/hymn/supp-1',
      '/reading/reading-1',
      '/readings',
      '/settings',
    ]) {
      testWidgets('$location meets the guidelines in ${theme.name}', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        useTallScreen(tester);
        await pumpApp(
          tester,
          db,
          location: location,
          settings: ReadingSettings(theme: theme),
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  }
}
