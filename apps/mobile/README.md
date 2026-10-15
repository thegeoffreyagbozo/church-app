# apps/mobile: the congregation app

Piece 1 is the hymn book and readings, fully offline (ADR 0009). The app opens a hymn book
database built by `packages/content_db` and bundled as an asset.

## Run it

1. Build the hymn book once, and again whenever the content changes. From the repo root:

   ```bash
   (cd packages/content_db && dart run build_runner build --delete-conflicting-outputs)
   dart run content_db:build_content_db --config config/dev.json \
     --out apps/mobile/assets/content/content.db
   ```

   Without a Supabase project, use the public-domain sample instead:
   `--from-json packages/content_db/test/fixtures/sample_content.json`. The file is
   git-ignored because it is church content.
2. Run with a church settings file (colours and tagline) and the environment config:

   ```bash
   cd apps/mobile
   flutter run --dart-define-from-file=../../churches/example/church.json \
     --dart-define-from-file=../../config/dev.json
   ```

## Test it

- `flutter test`: unit, widget, accessibility and golden screenshot tests (CI runs the same).
- After a deliberate visual change: `flutter test --update-goldens test/goldens_test.dart`, then
  look at the images in `test/goldens/` before committing them.
- The speed check runs on an emulator or phone, from a first launch with no network:

  ```bash
  adb uninstall com.example.church_app || true
  adb shell cmd connectivity airplane-mode enable
  flutter drive --profile --driver=test_driver/integration_test.dart \
    --target=integration_test/pew_flow_test.dart \
    --dart-define-from-file=../../churches/example/church.json
  adb shell cmd connectivity airplane-mode disable
  ```

  It times a number search, the hymn opening until its words show, and a word typed one
  letter at a time. It fails if results take 100 ms or more after the last key, or a hymn
  takes 300 ms or more to show its words. It prints the timings and, when the targets hold,
  saves them in `build/integration_response_data.json`. For the cold start, run
  `adb shell am force-stop com.example.church_app` and then
  `adb shell am start -W -n com.example.church_app/.MainActivity`: `TotalTime` should stay
  under 2000 ms.

## Fonts

Literata, Fraunces, Inter and Atkinson Hyperlegible (SIL Open Font License 1.1) are in
`assets/fonts` with their licences in `assets/fonts/licenses` (Settings, Licences shows them).
`tool/fetch_fonts.sh` downloads them again.

## Layout

```
lib/
  main.dart, startup.dart, app.dart
  core/       config, theme, database, platform, router, shared widgets, labels
  features/   home, search, hymnal, readings, settings, item_menu (domain / data / presentation)
```
