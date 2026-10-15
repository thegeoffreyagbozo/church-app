import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../domain/reading_markup.dart';

/// One part of a reading. The two voices have no labels (spec section 3.5): the bold
/// voice sits on a soft band; the other is plain. In a reading everyone says together,
/// every part is plain.
class ReadingPartView extends StatelessWidget {
  const ReadingPartView(this.part, {super.key, required this.together});

  final ReadingPartText part;

  /// Whether the whole reading is read together (no band).
  final bool together;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final bold =
        !together &&
        (part.speaker == ReadingSpeaker.people ||
            part.speaker == ReadingSpeaker.all);
    final style = bold ? theme.text.bold : theme.text.verse;
    final text = _Markup(part.body, style: style);
    final body = part.scriptureRef == null
        ? text
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: 4),
              Text(
                part.scriptureRef!,
                textAlign: TextAlign.end,
                style: theme.text.credits,
              ),
            ],
          );
    final numbered = part.number == null
        ? body
        : Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Grows with the text size; an item number never breaks across
              // lines or spills over the words.
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.textScalerOf(context).scale(32),
                ),
                child: Text(
                  '${part.number}',
                  softWrap: false,
                  style: theme.text.itemNumber,
                ),
              ),
              Expanded(child: body),
            ],
          );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: bold
          ? BoxDecoration(
              color: theme.palette.band,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: numbered,
    );
  }
}

/// A part's lines: paragraphs and bullets with **bold** runs.
class _Markup extends StatelessWidget {
  const _Markup(this.body, {required this.style});

  final String body;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final accent = HymnalTheme.of(context).palette.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in parseReadingMarkup(body))
          Padding(
            padding: EdgeInsets.only(left: line.bullet ? 4 : 0, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (line.bullet)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text('•', style: style.copyWith(color: accent)),
                  ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        for (final run in line.runs)
                          TextSpan(
                            text: run.text,
                            style: run.bold
                                ? const TextStyle(fontWeight: FontWeight.w700)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
