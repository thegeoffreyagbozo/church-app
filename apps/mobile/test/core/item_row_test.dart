import 'package:church_app/core/config/church_config.dart';
import 'package:church_app/core/theme/hymnal_theme.dart';
import 'package:church_app/core/theme/palette.dart';
import 'package:church_app/core/widgets/item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/text_lines.dart';

void main() {
  Future<void> pumpRow(WidgetTester tester, int number, double textScale) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(
            HymnalPalette.paper(
              primary: ChurchConfig.defaultPrimary,
              accent: ChurchConfig.defaultAccent,
            ),
          ),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: ItemRow(
                number: number,
                title: const Text('How Firm a Foundation'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

  for (final textScale in [1.3, 2.0]) {
    testWidgets('a long number stays on one line at ${textScale}x text', (
      tester,
    ) async {
      await pumpRow(tester, 268, textScale);

      expect(linesOf(tester, '268'), 1);
    });
  }
}
