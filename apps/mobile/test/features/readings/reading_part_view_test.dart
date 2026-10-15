import 'package:church_app/core/config/church_config.dart';
import 'package:church_app/core/theme/hymnal_theme.dart';
import 'package:church_app/core/theme/palette.dart';
import 'package:church_app/features/readings/presentation/reading_part_view.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_lines.dart';

void main() {
  // 1.5x wraps a fixed column; at 2.5x the number spills over the words instead.
  for (final textScale in [1.5, 2.5]) {
    testWidgets(
      'a two-digit item number fits its column at ${textScale}x text',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(
              HymnalPalette.paper(
                primary: ChurchConfig.defaultPrimary,
                accent: ChurchConfig.defaultAccent,
              ),
            ),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const Scaffold(
                body: ReadingPartView(
                  ReadingPartText(
                    number: 10,
                    body: 'The Lord bless thee, and keep thee.',
                    scriptureRef: 'Numbers 6:24',
                  ),
                  together: false,
                ),
              ),
            ),
          ),
        );

        final number = tester.renderObject<RenderParagraph>(find.text('10'));
        expect(linesOf(tester, '10'), 1);
        expect(
          number.size.width,
          greaterThanOrEqualTo(number.getMaxIntrinsicWidth(double.infinity)),
        );
      },
    );
  }
}
