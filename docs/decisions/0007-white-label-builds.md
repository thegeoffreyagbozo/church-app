# ADR 0007: White-label builds, one codebase and one deployment per church

**Status:** Accepted · **Date:** 2026-10-11 · **Extends:** [ADR 0005](./0005-single-church-no-multitenancy.md)

## Context
The app is becoming a product for many churches, and each church wants its own app in the
stores: its own name, icon, package ID and branding. ADR 0005 designed the backend for a single
church. The stores also limit how template apps can be published: Apple guideline 4.2.6 rejects
them unless they are submitted by the provider of the app's content (or shipped as one "picker"
app that hosts every client), and Google strongly recommends a separate developer account per
white-label client.

## Decision
- **One codebase, one deployment per church.** Each church gets its own app build, its own
  Supabase project, and its own store listings. Within a deployment the single-church design of
  ADR 0005 applies unchanged, so the schema and RLS need no tenant column.
- **Identity and branding are config, not code.** A church is a folder, `churches/<slug>/`
  (slug: for example the church's domain name without the TLD), holding:
  - `church.json`: `APP_NAME` (home-screen label), `APP_ID` (Android applicationId and iOS
    bundle ID), `BRAND_PRIMARY` and `BRAND_ACCENT` (the two brand colours as `#RRGGBB`), an
    optional `CHURCH_TAGLINE` (a line under the church name on Home), and similar public values
    (see `churches/README.md`);
  - `prod.json`: that church's backend (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, later the Paystack
    public key);
  - icon and splash images.

  A build passes both files and Flutter merges them, later files winning:
  `--dart-define-from-file=churches/<slug>/church.json --dart-define-from-file=churches/<slug>/prod.json`.
  Development builds pair a church file with `config/dev.json` (ADR 0006).
- **Native identity is read from that config.** Flutter hands define-file values to native
  builds only as one encoded list (the `dart-defines` Gradle property and the `DART_DEFINES`
  Xcode setting: base64 of each `KEY=VALUE`, comma-joined). The Android Gradle file and an iOS
  scheme pre-action decode it to set the app name and package ID, so adding a church needs no
  code or native project changes. Icons and splash screens get a per-church generation step.
- **Real church configs never enter git.** The repository is public, so `churches/*` is
  git-ignored except a committed `churches/example/` template with placeholder values. Real
  configs and branding live only on the build machine, with a private backup. If CI ever builds
  church apps, it receives their config from repository secrets.
- **Each church owns its store presence.** The church enrolls its own Apple Developer and Google
  Play accounts (as an organization, which needs a free D-U-N-S number) and publishes its own
  app; the developer joins those accounts to build and submit.
- **Package ID = the church's domain, reversed** (for example `com.examplechurch.app`). It is
  permanent once published. Development builds use the example template's identity.

## Consequences
- Adding a church means a config folder, a Supabase project and store listings; no code changes.
- Each church's data lives in its own project and is owned by that church, which keeps
  data-protection responsibilities clear (Ghana Data Protection Act).
- Operations become per church: keepalive pings and nightly backups run for every church
  project, and releases are built per church.
- Supabase's free plan is limited to two active projects, so production church projects need a
  paid plan or the church's own Supabase account. Free projects also pause when idle, hence the
  keepalive.
- A fix reaches a church only once that church's app is rebuilt and released.

## Alternatives rejected
- **One app with a church picker (multi-tenant).** Apple allows it, but it needs `church_id` on
  every table plus tenant-scoped RLS (reversing ADR 0005), puts every church's data in one
  backend, and no church gets its own branded app.
- **Static Flutter flavors per church.** Adding a church would mean editing Gradle and creating
  Xcode schemes and build configurations each time; it does not scale.
- **One developer account publishing every church's app.** Rejected by Apple 4.2.6, discouraged
  by Google, and a single policy strike could remove every church's app at once.
