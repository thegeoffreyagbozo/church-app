import 'package:church_app/features/item_menu/domain/report.dart';
import 'package:church_app/features/item_menu/domain/share_text.dart';
import 'package:church_app/l10n/app_localizations_en.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const section = Section(id: 'h', name: 'Hymns', isDefault: true, count: 1);
  HymnDetail hymn({required bool publicDomain}) => HymnDetail(
    id: 'h1',
    section: section,
    number: 1,
    title: 'Rock of Ages',
    isPublicDomain: publicDomain,
    alsoSungTo: const [],
    texts: const [
      HymnText(
        type: HymnSectionType.verse,
        number: 1,
        lyrics: 'Rock of Ages,\ncleft for me',
      ),
      HymnText(type: HymnSectionType.chorus, lyrics: 'A chorus'),
    ],
  );

  test('shares the words of a public-domain hymn', () {
    expect(
      hymnShareText(l10n, hymn(publicDomain: true), churchName: 'Grace Chapel'),
      'Hymn 1 · Rock of Ages\n\n'
      'Verse 1\nRock of Ages,\ncleft for me\n\n'
      'Chorus\nA chorus\n\n'
      'Shared from Grace Chapel',
    );
  });

  test('shares only the number and title otherwise', () {
    expect(
      hymnShareText(
        l10n,
        hymn(publicDomain: false),
        churchName: 'Grace Chapel',
      ),
      'Hymn 1 · Rock of Ages\n\nShared from Grace Chapel',
    );
  });

  test('shares a reading with its reference and plain text', () {
    const reading = ReadingDetail(
      id: 'r',
      kind: ReadingKind.benediction,
      number: 3,
      title: 'Benedictions',
      isPublicDomain: true,
      parts: [
        ReadingPartText(
          number: 1,
          body: 'The Lord **bless** thee.',
          scriptureRef: 'Numbers 6:24',
        ),
      ],
    );

    expect(
      readingShareText(l10n, reading, churchName: 'Grace Chapel'),
      'Reading 3 · Benedictions\n\n1.\nThe Lord bless thee.\nNumbers 6:24\n\nShared from Grace Chapel',
    );
  });

  group('ReportTarget', () {
    test('uses the WhatsApp number, else the phone, as digits', () {
      expect(
        ReportTarget.of(
          const ChurchProfile(name: 'x', phone: '+233 20 000 0000'),
        )!.whatsappNumber,
        '233200000000',
      );
      expect(
        ReportTarget.of(
          const ChurchProfile(name: 'x', whatsapp: '+233 24', phone: '+233 20'),
        )!.whatsappNumber,
        '23324',
      );
    });

    test('is null without any contact', () {
      expect(ReportTarget.of(const ChurchProfile(name: 'x')), isNull);
      expect(ReportTarget.of(null), isNull);
    });

    test('builds the WhatsApp and email links', () {
      const target = ReportTarget(
        whatsappNumber: '233200000000',
        email: 'a@b.c',
      );

      expect(
        target.whatsappUri('Mistake in Hymn 1: ').toString(),
        'whatsapp://send?phone=233200000000&text=Mistake%20in%20Hymn%201%3A%20',
      );
      expect(
        target.emailUri('Mistake in Hymn 1', 'Mistake in Hymn 1: ').toString(),
        'mailto:a@b.c?subject=Mistake%20in%20Hymn%201&body=Mistake%20in%20Hymn%201%3A%20',
      );
    });
  });
}
