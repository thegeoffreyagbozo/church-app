# Church App

A mobile-first, **offline-first** app for churches in Ghana, built in small shippable slices. One
codebase is built and deployed separately for each church ([ADR 0007](docs/decisions/0007-white-label-builds.md)).
**v1.0.0 is an offline hymnal**; later slices add events, media, giving/pledges, notifications,
a cooperative focus mode, notes, and a Bible.

> 📐 **Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) first** — the full approved plan.
> Every significant decision is recorded in [`docs/decisions/`](docs/decisions/).

## Stack

| Part | Tech |
|---|---|
| Mobile app (iOS+Android) | Flutter · Riverpod · go_router · **drift** (offline SQLite + FTS5) |
| Backend | Supabase (Postgres + Auth + Storage + Edge Functions), RLS everywhere |
| Admin panel | React + TypeScript (Vite, react-admin) → Cloudflare Pages |
| Media | YouTube/Vimeo (video) · Cloudflare R2 (audio/files, zero egress) · Supabase Storage (images, sheet-music PDFs) |
| Payments (later) | Paystack — Ghana mobile money + cards, GHS |
| Push (later) | Firebase Cloud Messaging + local notifications |

## Monorepo layout

```
apps/mobile/       Flutter app (iOS + Android)
packages/shared/   Shared Dart models, enums, DTOs (mobile-only)
admin/             React + TS admin SPA (own package.json)
supabase/          config.toml · migrations/ · functions/ · seed.sql
config/            per-env public config (JSON; git-ignored except example.json)
docs/              ARCHITECTURE.md + decision records (ADRs)
.github/workflows/ CI, keepalive, backups
```

## Getting started

Requires **Flutter SDK (Dart ≥ 3.6)**, **Node ≥ 20 / pnpm**, the **Supabase CLI**, and **Deno**
(for Edge Functions). Not all are present in every environment — see
[`docs/decisions/0006-config-and-secrets.md`](docs/decisions/0006-config-and-secrets.md) for
config, and the per-folder READMEs.

```bash
# 1. Config (public keys only — never secrets)
cp config/example.json config/dev.json      # fill in SUPABASE_URL, SUPABASE_ANON_KEY, ...

# 2. Backend (needs Docker for local, or push to a cloud project)
cd supabase && supabase start                 # local stack
#   or: supabase db push                       # apply migrations to your cloud project
supabase db reset                              # apply migrations + seed.sql

# 3. Mobile app
cd apps/mobile
flutter create --platforms=android,ios .       # generate native shells (first time only)
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=../../config/dev.json

# 4. Admin panel
cd admin && pnpm install && pnpm dev
```

## Configuration & secrets

**Only public keys ever reach a client.** The app reads a JSON config via
`--dart-define-from-file`; the admin uses `VITE_`-prefixed `.env`; true secrets (service-role
key, Paystack secret, R2 keys, FCM account) live only in Supabase/GitHub secret stores. Full
rule: [`docs/decisions/0006-config-and-secrets.md`](docs/decisions/0006-config-and-secrets.md).

## Status

🟡 **Foundation stage** — backend schema, monorepo scaffold, and CI are being laid down. The
Flutter hymnal app and React admin follow. See `docs/ARCHITECTURE.md` → "Implementation steps".
