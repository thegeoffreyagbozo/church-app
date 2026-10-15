import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

/// Paper, Night, or Auto (follow the phone).
enum ReadingTheme { paper, night, auto }

/// How hymns and readings are shown; saved on the phone (spec section 3.7).
@immutable
class ReadingSettings {
  const ReadingSettings({
    this.textScale = 1.0,
    this.theme = ReadingTheme.auto,
    this.legibleType = false,
    this.keepScreenOn = true,
    this.digitRow = true,
    this.hymnView = HymnViewMode.ordinary,
  });

  /// Reads the saved values, falling back to the defaults for anything missing or
  /// unreadable.
  factory ReadingSettings.fromMap(Map<String, String> map) {
    const defaults = ReadingSettings();
    bool flag(String key, bool fallback) => switch (map[key]) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };
    return ReadingSettings(
      textScale: clampTextScale(
        double.tryParse(map[_textScale] ?? '') ?? defaults.textScale,
      ),
      theme: ReadingTheme.values.asNameMap()[map[_theme]] ?? defaults.theme,
      legibleType: flag(_legibleType, defaults.legibleType),
      keepScreenOn: flag(_keepScreenOn, defaults.keepScreenOn),
      digitRow: flag(_digitRow, defaults.digitRow),
      hymnView:
          HymnViewMode.values.asNameMap()[map[_hymnView]] ?? defaults.hymnView,
    );
  }

  static const minTextScale = 0.5;
  static const maxTextScale = 2.0;

  static double clampTextScale(double value) =>
      value.clamp(minTextScale, maxTextScale).toDouble();

  static const _textScale = 'text_scale';
  static const _theme = 'theme';
  static const _legibleType = 'legible_type';
  static const _keepScreenOn = 'keep_screen_on';
  static const _digitRow = 'digit_row';
  static const _hymnView = 'hymn_view';

  /// The reader's own text size, multiplied with the phone's (0.5 to 2.0).
  final double textScale;
  final ReadingTheme theme;
  final bool legibleType;
  final bool keepScreenOn;

  /// Whether the app draws a row of digits above the keyboard while searching.
  final bool digitRow;

  /// Words or Music on hymn pages.
  final HymnViewMode hymnView;

  Map<String, String> toMap() => {
    _textScale: textScale.toStringAsFixed(2),
    _theme: theme.name,
    _legibleType: '$legibleType',
    _keepScreenOn: '$keepScreenOn',
    _digitRow: '$digitRow',
    _hymnView: hymnView.name,
  };

  ReadingSettings copyWith({
    double? textScale,
    ReadingTheme? theme,
    bool? legibleType,
    bool? keepScreenOn,
    bool? digitRow,
    HymnViewMode? hymnView,
  }) => ReadingSettings(
    textScale: textScale ?? this.textScale,
    theme: theme ?? this.theme,
    legibleType: legibleType ?? this.legibleType,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    digitRow: digitRow ?? this.digitRow,
    hymnView: hymnView ?? this.hymnView,
  );

  @override
  bool operator ==(Object other) =>
      other is ReadingSettings &&
      other.textScale == textScale &&
      other.theme == theme &&
      other.legibleType == legibleType &&
      other.keepScreenOn == keepScreenOn &&
      other.digitRow == digitRow &&
      other.hymnView == hymnView;

  @override
  int get hashCode => Object.hash(
    textScale,
    theme,
    legibleType,
    keepScreenOn,
    digitRow,
    hymnView,
  );
}
