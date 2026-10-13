import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';

/// Text with the search's matched words (between [markStart] and [markEnd]) shown in
/// a soft highlight.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.style,
    required this.highlight,
    this.prefix,
    this.maxLines,
  });

  final String text;
  final TextStyle style;

  /// Background of a matched word.
  final Color highlight;

  /// Shown before the text, such as "VERSE 4 · ".
  final InlineSpan? prefix;
  final int? maxLines;

  /// [text] without the match markers.
  static String plain(String text) =>
      text.replaceAll(markStart, '').replaceAll(markEnd, '');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[?prefix];
    final parts = text.split(markStart);
    if (parts.first.isNotEmpty) spans.add(TextSpan(text: parts.first));
    for (final part in parts.skip(1)) {
      final end = part.indexOf(markEnd);
      final match = end < 0 ? part : part.substring(0, end);
      spans.add(
        TextSpan(
          text: match,
          style: TextStyle(
            backgroundColor: highlight,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
      if (end >= 0 && end + 1 < part.length) {
        spans.add(TextSpan(text: part.substring(end + 1)));
      }
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
