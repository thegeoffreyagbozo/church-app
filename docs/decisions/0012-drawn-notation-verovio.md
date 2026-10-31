# ADR 0012: Drawn notation with Verovio

**Status:** Accepted · **Date:** 2026-10-31 · **Amends:** [ADR 0011](0011-sheet-music-images.md)

## Context
The choir reads staff notation. Scanned pages (ADR 0011) are fixed pictures: on a phone they
have to be pinch-zoomed, they show every verse at once and can't pick out one voice.

## Decision
- **The app draws notation** from a hymn's MusicXML with Verovio 6.3.0 (LGPL-3.0, built from
  source by `packages/notation` and linked as a shared library). The music re-flows to the
  screen, one verse sits under the notes, and the chorister's part stays in full ink while the
  other voices fade to 0.35.
- **Data:** one `.mxl` per hymn, laid out as two staves with soprano and alto, tenor and bass,
  words on the soprano. The importer checks the layout and the words against the batch text,
  and writes a `hymn_assets` row of kind `musicxml` (migration 0006) at
  `<hymn id>/notation.mxl`. The content build stores the file in `hymn_notation` (schema 5).
- **Music view:** notation first, then the scanned images, then the details card alone. Verse
  chips and an All, S, A, T, B part picker; the part is remembered. Every verse starts drawing
  when a hymn opens, and a part change re-fades a kept drawing instead of running Verovio again.
- **Trial:** a handful of hymns first, the Doxology the first of them.

## Go/no-go (30 Oct 2026)
On the Pixel 9 emulator, profile mode, a two-line four-part hymn: first drawing about 185 ms,
repeat 0 ms; release APK +10.6 MB for arm64 (Verovio 9.7 MB stripped), about 4 MB to download.
The owner judged it readable in Paper and Night and accepted the size; the Galaxy A15 was
broken, so a borrowed budget phone is timed before the choir trial.

## Alternatives
- **Our own Flutter engraver:** no native code, but engraving hymns well (spacing by words,
  two voices on a staff, accidentals) is a large job.
- **Drawings made at build time:** simpler app, but fixed widths and every verse and part
  combination, so no real re-flow.
- **All verses in one Verovio run:** instant verse switches, but every verse's row stays under
  the notes, leaving empty rows when one verse shows.

## Consequences
- The app is about 10 MB bigger installed. Notation reaches phones with the next app build
  until sync exists.
- `flutter_svg` can't draw Verovio's SVG as it comes (nested `<svg>`, `<style>`, unscaled text),
  so `packages/notation` reshapes it; a future `flutter_svg` that scales text would make the
  words too small.
- Every notation file needs entering and checking by someone who reads music.
