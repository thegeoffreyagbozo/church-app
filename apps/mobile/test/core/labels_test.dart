import 'package:church_app/core/labels.dart';
import 'package:church_app/l10n/app_localizations_en.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const hymns = Section(id: 'h', name: 'Hymns', isDefault: true, count: 1);
  const supplementary = Section(
    id: 's',
    name: 'Supplementary Hymns',
    isDefault: false,
    count: 1,
  );
  const service = Section(
    id: 'm',
    name: 'Service Music',
    isDefault: false,
    count: 1,
  );

  test('shortens section names that end in Hymns', () {
    expect(shortSectionName('Supplementary Hymns'), 'Supplementary');
    expect(shortSectionName('Service Music'), 'Service Music');
    expect(shortSectionName('Hymns'), 'Hymns');
  });

  test('kickers name the default section "Hymn"', () {
    expect(hymnKicker(l10n, hymns), 'Hymn');
    expect(hymnKicker(l10n, supplementary), 'Supplementary');
    expect(hymnKicker(l10n, service), 'Service Music');
  });

  test('names hymns and readings for messages', () {
    expect(hymnName(l10n, hymns, 41), 'Hymn 41');
    expect(hymnName(l10n, supplementary, 2), 'Supplementary 2');
    expect(hymnName(l10n, service, null), isNull);
    expect(
      itemLabel('Hymn 41', 'How Firm a Foundation'),
      'Hymn 41 · How Firm a Foundation',
    );
    expect(itemLabel(null, 'Doxology'), 'Doxology');
  });

  test('names readings by kind', () {
    expect(
      readingKicker(l10n, ReadingKind.responsiveReading),
      'Responsive reading',
    );
    expect(readingKicker(l10n, ReadingKind.benediction), 'Reading');
    expect(readingKicker(l10n, ReadingKind.covenant), 'Covenant');
  });

  test('labels verses and choruses', () {
    expect(sectionLabel(l10n, HymnSectionType.verse, 4), 'Verse 4');
    expect(sectionLabel(l10n, HymnSectionType.verse, null), 'Verse');
    expect(sectionLabel(l10n, HymnSectionType.refrain, null), 'Refrain');
  });
}
