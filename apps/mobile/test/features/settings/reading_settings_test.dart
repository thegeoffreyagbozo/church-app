import 'package:church_app/core/database/content_providers.dart';
import 'package:church_app/features/settings/domain/reading_settings.dart';
import 'package:church_app/features/settings/presentation/settings_controller.dart';
import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('ReadingSettings', () {
    test('defaults: normal size, Auto theme, screen kept on, number row', () {
      const settings = ReadingSettings();

      expect(settings.textScale, 1);
      expect(settings.theme, ReadingTheme.auto);
      expect(settings.keepScreenOn, isTrue);
      expect(settings.digitRow, isTrue);
      expect(settings.hymnView, HymnViewMode.ordinary);
    });

    test('round-trips through the saved values', () {
      const settings = ReadingSettings(
        textScale: 1.4,
        theme: ReadingTheme.night,
        legibleType: true,
        keepScreenOn: false,
        digitRow: false,
        hymnView: HymnViewMode.chorister,
      );

      expect(ReadingSettings.fromMap(settings.toMap()), settings);
    });

    test('ignores unreadable values and keeps sizes in range', () {
      final settings = ReadingSettings.fromMap({
        'text_scale': '9',
        'theme': 'purple',
        'keep_screen_on': 'maybe',
      });

      expect(settings.textScale, ReadingSettings.maxTextScale);
      expect(settings.theme, ReadingTheme.auto);
      expect(settings.keepScreenOn, isTrue);
    });

    test('text can be as small as half the normal size', () {
      expect(ReadingSettings.fromMap({'text_scale': '0.5'}).textScale, 0.5);
      expect(ReadingSettings.fromMap({'text_scale': '0.3'}).textScale, 0.5);
    });
  });

  group('ReadingSettingsController', () {
    late ContentDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = ContentDatabase(NativeDatabase.memory());
      container = ProviderContainer.test(
        overrides: [contentDatabaseProvider.overrideWithValue(db)],
      );
    });
    tearDown(() => db.close());

    test('saves each change on the phone', () async {
      container
          .read(readingSettingsProvider.notifier)
          .setTheme(ReadingTheme.night);
      await pumpEventQueue();

      expect((await UserData(db).settings())['theme'], 'night');
    });

    test('a pinch preview is saved only when it ends', () async {
      final controller = container.read(readingSettingsProvider.notifier);

      controller.previewTextScale(1.7);
      await pumpEventQueue();
      expect(await UserData(db).settings(), isEmpty);
      expect(container.read(readingSettingsProvider).textScale, 1.7);

      controller.commitTextScale();
      await pumpEventQueue();
      expect((await UserData(db).settings())['text_scale'], '1.70');
    });
  });
}
