# apps/mobile — Flutter app (iOS + Android)

The congregation-facing app. **Offline-first**: the UI reads from a local **drift** (SQLite)
database and syncs with Supabase in the background. v1.0.0 is the hymnal.

> **Status:** scaffolded next. The app spine (`main.dart` bootstrap, `core/`, `features/hymnal/`,
> the sync engine) lands in Implementation Step 5 of [`../../docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md).
> When it does, `apps/mobile` is added back to the root `pubspec.yaml` workspace.

## First-time setup (requires the Flutter SDK)

```bash
# Generate the native iOS/Android shells over this package (first time only):
flutter create --platforms=android,ios --org com.yourchurch --project-name church_app .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=../../config/dev.json
```

## Layout (target)

```
lib/
  main.dart            bootstrap: open drift → Supabase.init → ensure anon session → runApp
  app.dart             MaterialApp.router, themes, l10n
  core/                theme tokens · router · Riverpod DI · drift AppDatabase · sync engine ·
                       connectivity · error/Result · l10n · shared widgets
  features/
    hymnal/            domain/ · data/ · presentation/   (the triad every feature copies)
    settings/
```

See [`docs/decisions`](../../docs/decisions) for the canonical architecture rules this app follows.
