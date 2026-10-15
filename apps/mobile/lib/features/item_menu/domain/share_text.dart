import 'package:content_db/content_db.dart';

import '../../../core/labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../readings/domain/reading_markup.dart';

/// What the share sheet sends for a hymn: the words only when they are public domain,
/// otherwise just the number and title (spec section 3.6).
String hymnShareText(
  AppLocalizations l10n,
  HymnDetail hymn, {
  required String churchName,
}) {
  final heading = itemLabel(
    hymnName(l10n, hymn.section, hymn.number),
    hymn.title,
  );
  final body = [
    if (hymn.isPublicDomain)
      for (final text in hymn.texts)
        '${sectionLabel(l10n, text.type, text.number)}\n${text.lyrics}',
  ];
  return [heading, ...body, l10n.sharedFrom(churchName)].join('\n\n');
}

String readingShareText(
  AppLocalizations l10n,
  ReadingDetail reading, {
  required String churchName,
}) {
  final heading = [
    itemLabel(readingName(l10n, reading.number), reading.title),
    ?reading.scriptureRef,
  ].join('\n');
  final body = [
    if (reading.isPublicDomain)
      for (final part in reading.parts)
        [
          if (part.number != null) '${part.number}.',
          plainReadingText(part.body),
          ?part.scriptureRef,
        ].join('\n'),
  ];
  return [heading, ...body, l10n.sharedFrom(churchName)].join('\n\n');
}
