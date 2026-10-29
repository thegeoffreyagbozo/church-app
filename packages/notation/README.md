# packages/notation

Draws a hymn's MusicXML on the phone with [Verovio](https://www.verovio.org) (LGPL-3.0),
built from a pinned release by `src/CMakeLists.txt` as `libverovio.so`. Android only for now.
Nothing in the app uses it yet: it is the go/no-go for drawn notation.

- `example/` shows the drawing and holds the device tests:
  `flutter test integration_test/engine_test.dart -d <device>` from `example/`.
