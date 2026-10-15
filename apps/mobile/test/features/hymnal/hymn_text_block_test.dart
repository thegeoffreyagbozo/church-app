import 'package:church_app/core/config/church_config.dart';
import 'package:church_app/core/theme/hymnal_theme.dart';
import 'package:church_app/core/theme/palette.dart';
import 'package:church_app/features/hymnal/presentation/hymn_text_block.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../helpers/text_lines.dart';

void main() {
  testWidgets('a two-digit verse number stays on one line at large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(
          HymnalPalette.paper(
            primary: ChurchConfig.defaultPrimary,
            accent: ChurchConfig.defaultAccent,
          ),
        ),
        // The largest the words get: the reader's size times the phone's, capped.
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.5)),
          child: Scaffold(
            body: HymnTextBlock(
              HymnText(
                type: HymnSectionType.verse,
                number: 12,
                lyrics: 'Words of the twelfth verse',
              ),
            ),
          ),
        ),
      ),
    );

    expect(linesOf(tester, '12'), 1);
  });
}
