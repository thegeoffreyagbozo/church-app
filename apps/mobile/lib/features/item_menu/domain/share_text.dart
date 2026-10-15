import 'package:content_db/content_db.dart';

import '../../../core/labels.dart';
import '../../../l10n/app_localizations.dart';

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
