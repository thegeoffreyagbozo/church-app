import 'package:content_db/content_db.dart';
import 'package:shared/shared.dart';

import '../l10n/app_localizations.dart';

// Names of sections, items and verses as the app shows them.

/// A section's name without a trailing "Hymns": "Supplementary Hymns" becomes
/// "Supplementary", while "Service Music" stays.
String shortSectionName(String name) {
  final match = RegExp(
    r'^(.+?)\s+hymns$',
    caseSensitive: false,
  ).firstMatch(name);
  return match == null ? name : match[1]!;
}

/// The kicker above a hymn: "Hymn" in the default section, else the section's short
/// name. Kickers are drawn in capitals.
String hymnKicker(AppLocalizations l10n, Section section) =>
    section.isDefault ? l10n.kickerHymn : shortSectionName(section.name);

String readingKicker(AppLocalizations l10n, ReadingKind kind) => switch (kind) {
  ReadingKind.responsiveReading => l10n.kickerResponsiveReading,
  ReadingKind.callToWorship || ReadingKind.benediction => l10n.kickerReading,
  ReadingKind.creed => l10n.kickerCreed,
  ReadingKind.covenant => l10n.kickerCovenant,
};

/// How to name a hymn in a message: "Hymn 41", "Supplementary 2", or null when it has
/// no number.
String? hymnName(AppLocalizations l10n, Section section, int? number) {
  if (number == null) return null;
  return section.isDefault
      ? l10n.hymnName(number)
      : '${shortSectionName(section.name)} $number';
}

String? readingName(AppLocalizations l10n, int? number) =>
    number == null ? null : l10n.readingName(number);

/// "Hymn 41 · How Firm a Foundation", or just the title when there is no number.
String itemLabel(String? name, String title) =>
    name == null ? title : '$name · $title';

/// "Verse 4", "Chorus" and so on, for a hymn section.
String sectionLabel(AppLocalizations l10n, HymnSectionType type, int? number) =>
    switch (type) {
      HymnSectionType.verse =>
        number == null ? l10n.verse : l10n.verseLabel(number),
      HymnSectionType.chorus => l10n.chorusLabel,
      HymnSectionType.refrain => l10n.refrainLabel,
      HymnSectionType.bridge => l10n.bridgeLabel,
      HymnSectionType.preChorus => l10n.preChorusLabel,
      HymnSectionType.ending => l10n.endingLabel,
    };
