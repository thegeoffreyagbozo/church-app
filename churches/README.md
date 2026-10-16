# churches/

One folder per church (ADR 0007). Only `example/` is committed: real churches' folders stay on
the build machine, with a private backup.

- `church.json`: the church's public identity and branding, passed to builds with
  `--dart-define-from-file`.
- `prod.json`: that church's backend (added with per-church builds, piece 3).
- `branding/`: the church's logo and icons, under the fixed names below.
- `android/`: made on the build machine. `res/` holds the launcher icons and the launch
  screen (the church's colour, its logo and its wordmark), written by
  `dart run tool/church_branding.dart ../../churches/<slug>` from `apps/mobile`; run it
  again after changing an image. `key.properties` and `upload-keystore.jks` are the church's
  release key (see `apps/mobile/README.md`); keep a private backup. Builds made with the
  church's settings file use both: Gradle finds the folder whose `church.json` has the
  build's `APP_ID`.

| Key | Meaning |
|---|---|
| `APP_NAME` | Home-screen label (Android now, iOS from piece 3) |
| `APP_ID` | Package ID: the church's domain reversed (Android now, iOS from piece 3) |
| `BRAND_PRIMARY` | Numbers, buttons and the reading band, as `#RRGGBB` |
| `BRAND_ACCENT` | Kickers and verse numbers, as `#RRGGBB` |
| `CHURCH_TAGLINE` | Optional line under the church name on Home; leave empty for none |

The app adjusts both colours until all text on Paper and Night meets WCAG AA, so any brand
colours work. Without a settings file the app uses neutral ink blue and oxblood.

## Branding files

| File | What it is |
|---|---|
| `icon.png` | 1024 x 1024 (at least 960): the whole icon on its background, for Android before 8 |
| `icon_foreground.png` | 1024 x 1024: the artwork on transparent, inside the central circle of about 626 px; Android draws it on `BRAND_PRIMARY` |
| `icon_monochrome.png` | 1024 x 1024: a one-colour silhouette on transparent, for Android 13 themed icons |
| `splash_branding.png` | Optional, 800 x 320: the church's wordmark, white on transparent, under the logo on the launch screen (on `BRAND_PRIMARY`) |
| `logo.svg`, `logo.png`, `glyph.svg` | The logo and the cross alone, for later (iOS, notifications) |
