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
2. Run with a church settings file (name, package ID, colours and tagline) and the
   environment config:

   ```bash
   cd apps/mobile
   flutter run --dart-define-from-file=../../churches/example/church.json \
     --dart-define-from-file=../../config/dev.json
   ```

## Build a church's Android app

For a church with a folder in `churches/` (see `churches/README.md`), from `apps/mobile`:

1. Build the hymn book from the church's content, as in "Run it".
2. Make the launcher icons and launch screen:
   `dart run tool/church_branding.dart ../../churches/<slug>`.
3. Once per church, make its release key in `churches/<slug>/android/` and back it up
   privately. Every update must be signed with this key, or phones won't install it over
   the old one.

   ```bash
   keytool -genkeypair -keystore upload-keystore.jks -storetype PKCS12 -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

   Beside it, `key.properties` names the key and its password (the same password twice):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

4. Build one install file for any Android phone:

   ```bash
   flutter build apk --release --dart-define-from-file=../../churches/<slug>/church.json
   ```

   `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk` shows the
   church's name, not "Android Debug". Raise the build number in `pubspec.yaml` (`+2`, `+3`)
   for each update.

## Test it

- `flutter test`: unit, widget, accessibility and golden screenshot tests (CI runs the same).
- After a deliberate visual change: `flutter test --update-goldens test/goldens_test.dart`, then
  look at the images in `test/goldens/` before committing them.
- The speed check runs on an emulator or phone, from a first launch with no network:

  ```bash
  adb uninstall com.example.churchapp || true
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
  `adb shell am force-stop com.example.churchapp` and then
  `adb shell am start -W -n com.example.churchapp/com.example.church_app.MainActivity`:
  `TotalTime` should stay under 2000 ms. The package ID is the church file's `APP_ID`; the
  activity keeps the app's own namespace.

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
