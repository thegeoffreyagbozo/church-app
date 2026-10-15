import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// How many lines the text [text] was laid out on.
int linesOf(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}
