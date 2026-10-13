import 'package:flutter/painting.dart';

import 'palette.dart';

/// The text styles of the Hymnal design. Sizes are for 1x text; the reading pages scale
/// them with the reader's text size (see reading_text_scale.dart).
class HymnalType {
  const HymnalType(this.palette, {this.legible = false});

  final HymnalPalette palette;

  /// Swaps Literata and Inter for Atkinson Hyperlegible ("Extra-legible type").
  final bool legible;

  String get _serif => legible ? 'AtkinsonHyperlegible' : 'Literata';
  String get _sans => legible ? 'AtkinsonHyperlegible' : 'Inter';
  static const _numerals = 'Fraunces';

  /// Small capitals above a title: "HYMN", "SUPPLEMENTARY".
  TextStyle get kicker => TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.9,
    color: palette.accent,
  );

  /// The label of a chorus and of the Music card.
  TextStyle get label => kicker.copyWith(fontSize: 11, letterSpacing: 1.7);

  /// Section labels in lists, such as "RECENTLY OPENED".
  TextStyle get listLabel => label.copyWith(color: palette.muted);

  TextStyle get bigNumber => TextStyle(
    fontFamily: _numerals,
    fontSize: 64,
    height: 1.05,
    letterSpacing: -1.2,
    color: palette.primary,
  );

  TextStyle get pageTitle => TextStyle(
    fontFamily: _serif,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: palette.ink,
  );

  TextStyle get credits => TextStyle(
    fontFamily: _serif,
    fontSize: 15,
    fontStyle: FontStyle.italic,
    height: 1.45,
    color: palette.muted,
  );

  /// Hymn and reading text: 20 at 1x (spec section 7).
  TextStyle get verse => TextStyle(
    fontFamily: _serif,
    fontSize: 20,
    height: 1.6,
    color: palette.ink,
  );

  TextStyle get chorus => verse.copyWith(fontStyle: FontStyle.italic);

  /// The bold voice of a responsive reading.
  TextStyle get bold => verse.copyWith(fontWeight: FontWeight.w700);

  TextStyle get verseNumber => TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: palette.accent,
  );

  /// The number of an item in a collection, such as one benediction.
  TextStyle get itemNumber => TextStyle(
    fontFamily: _numerals,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: palette.primary,
  );

  TextStyle get listNumber => TextStyle(
    fontFamily: _numerals,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: palette.primary,
  );

  TextStyle get listTitle => TextStyle(
    fontFamily: _serif,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: palette.ink,
  );

  TextStyle get listSubtitle => TextStyle(
    fontFamily: _serif,
    fontSize: 15,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: palette.muted,
  );

  TextStyle get topHitNumber => TextStyle(
    fontFamily: _numerals,
    fontSize: 52,
    height: 1,
    color: palette.primary,
  );

  TextStyle get churchName => TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: palette.primary,
  );

  TextStyle get tagline => TextStyle(
    fontFamily: _serif,
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: palette.muted,
  );

  TextStyle get screenTitle => TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: palette.ink,
  );

  TextStyle get body => TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.4,
    color: palette.ink,
  );

  TextStyle get bodyStrong => body.copyWith(fontWeight: FontWeight.w600);

  TextStyle get caption => TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.35,
    color: palette.muted,
  );

  TextStyle get searchText =>
      TextStyle(fontFamily: _sans, fontSize: 18, color: palette.ink);

  /// The search text while it is only digits.
  TextStyle get searchNumber => TextStyle(
    fontFamily: _numerals,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: palette.primary,
  );

  TextStyle get digitKey => TextStyle(
    fontFamily: _numerals,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: palette.primary,
  );
}
