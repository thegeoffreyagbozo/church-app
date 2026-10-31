import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../../core/database/content_providers.dart';
import '../domain/reading_settings.dart';

/// The settings saved on the phone when the app started; startup overrides it.
final initialSettingsProvider = Provider<ReadingSettings>(
  (ref) => const ReadingSettings(),
);

final readingSettingsProvider =
    NotifierProvider<ReadingSettingsController, ReadingSettings>(
      ReadingSettingsController.new,
    );

/// Changes the reading settings and saves each change on the phone.
class ReadingSettingsController extends Notifier<ReadingSettings> {
  @override
  ReadingSettings build() => ref.watch(initialSettingsProvider);

  void setTextScale(double value) =>
      _save(state.copyWith(textScale: ReadingSettings.clampTextScale(value)));

  /// Shows [value] while a pinch is under way; [commitTextScale] saves it.
  void previewTextScale(double value) =>
      state = state.copyWith(textScale: ReadingSettings.clampTextScale(value));

  void commitTextScale() => _persist(state);

  void setTheme(ReadingTheme theme) => _save(state.copyWith(theme: theme));

  void setLegibleType(bool on) => _save(state.copyWith(legibleType: on));

  void setKeepScreenOn(bool on) => _save(state.copyWith(keepScreenOn: on));

  void setDigitRow(bool on) => _save(state.copyWith(digitRow: on));

  void setHymnView(HymnViewMode view) => _save(state.copyWith(hymnView: view));

  void setHymnPart(HymnPart part) => _save(state.copyWith(hymnPart: part));

  void _save(ReadingSettings next) {
    state = next;
    _persist(next);
  }

  void _persist(ReadingSettings settings) {
    final user = ref.read(userDataProvider);
    for (final MapEntry(:key, :value) in settings.toMap().entries) {
      unawaited(user.saveSetting(key, value));
    }
  }
}
