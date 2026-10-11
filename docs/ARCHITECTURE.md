# Church App — Architecture & Build Plan

## Context

We're starting a brand-new project (the repo is empty) for a **church in Ghana**: a
mobile-first app the congregation actually touches, with a public/member/staff split and
admin-managed content. The guiding principle is **ship in small slices** — a tiny, complete
first version, then grow — so the project proves its hardest technical bet early and never
stalls as a mega-build.

This plan exists because the owner (correctly) wanted the architecture and the hard design
decisions settled **before any code is written**. It was produced from a structured brainstorm
(4 rounds of scoping questions) plus a 6-domain architecture design pass and an adversarial
review. The intended outcome: a single, coherent, honest architecture everyone can build
against — and a concrete, testable **v1.0.0 = offline hymnal** to build first.

> **This plan is the design artifact, not an instruction to start coding.** Approving it means
> "the architecture is right." The first real coding step (scaffolding the monorepo) happens
> only after approval.

---

## Confirmed product decisions (from the brainstorm)

- **Client:** Flutter (one codebase → iOS + Android). **Offline-first is mandatory.**
- **Backend:** Supabase (free tier to start) — Postgres + Auth + Storage + Edge Functions.
- **Media:** Hybrid — **video** = YouTube/Vimeo links (free); **audio + downloadable files** =
  Cloudflare R2 (10 GB free, **zero egress**); **sheet-music PDFs + thumbnails** = Supabase
  Storage (public).
- **Platforms:** release to **both iOS and Android** once ready (Flutter builds both from one
  codebase). Budget Apple Developer $99/yr + Google Play $25 one-time.
- **Languages:** UI is **English-only at launch**; hymn *content* can be uploaded in Ghanaian
  languages (Twi/Ga/Ewe/Fante) via a per-hymn `language` field — content language is decoupled
  from UI locale, so this needs no extra UI translation work.
- **Sheet music:** distributed as **PDF per hymn**, in a **public** bucket, **visible to
  everyone** (not gated to choristers); rendered **offline** in the chorister view.
- **Payments (Ghana):** **Paystack** (Flutterwave kept swappable) — mobile money (MTN MoMo,
  Telecel Cash, AirtelTigo Money) + Visa/Mastercard, GHS. **Reminders-only pledges** (no
  auto-charge). Giving is **online-only**.
- **Identity:** profile = name + phone (email optional). Browsing is anonymous; an account is
  required only for giving/pledges/notes-sync. Login = phone + password + **optional TOTP 2FA**
  (authenticator app, **no SMS cost**). Phone unverified until giving.
- **Focus mode:** **cooperative only** — a worship/focus screen that detects & logs leaving,
  not a forced lock (platform reality; see Roadmap note). Geofencing is a later phase.
- **Admin:** a separate **web panel** for non-technical staff to manage all content.
- **Roadmap:** v1 = hymnal, then events → media → giving/pledges → notifications/focus → notes → bible.

---

## Tech stack (locked)

| Layer | Choice | Why |
|---|---|---|
| Mobile | **Flutter** | iOS+Android from one codebase |
| State + DI | **Riverpod 2 (code-gen)** | `AsyncValue` fits load-from-cache-then-refresh; providers double as DI (no get_it) |
| Navigation | **go_router** | declarative + deep links (needed for notification taps) |
| Local DB | **drift (SQLite)** | relational hymnal data, **FTS5 offline search**, migrations, reactive streams |
| Models | **freezed + json_serializable** | immutable entities + DTOs |
| Backend | **Supabase** (Postgres/Auth/Storage/Edge Functions) | managed, free tier, RLS |
| Media | **YouTube** (video) + **Cloudflare R2** (audio/files) + **Supabase Storage** (images) | zero-egress streaming, keeps free limits intact |
| Payments | **Paystack** (hosted checkout via `webview_flutter`) | Ghana MoMo+card, SAQ-A, webhook-verified |
| Push | **FCM** (`firebase_messaging`) + `flutter_local_notifications` | free; local reminders work offline |
| Admin panel | **React + TypeScript SPA** (react-admin + ra-supabase) on Cloudflare Pages | CRUD/dashboard ecosystem, lean bundle for slow connections; types generated from the DB |

---

## Canonical architecture decisions

These are the cross-cutting rules every slice obeys. (The review flagged that independent
design passes diverged here; these are the single sources of truth that resolve that.)

1. **Local-DB-first.** The UI always reads from the local **drift** DB (reactive streams).
   Network never blocks a read. Boot order: open drift → `Supabase.initialize` → ensure a
   session (restore, else **anonymous sign-in**) → `runApp` → background sync. A paused/offline
   backend degrades to "works offline, sync retries," never an error wall.

2. **One sync model.**
   - **Read content** (hymns, events, media, bible): one-way **delta pull** —
     `updated_at > cursor`, keyset-ordered on `(updated_at, id)`, idempotent upsert keyed on `id`.
   - **Deletions:** a soft-delete trigger writes to a **public `tombstones` table**; clients
     sweep `tombstones?deleted_at=gt.<cursor>` and purge locally. *(This is the single deletion
     mechanism — not "deleted rows come back in the main pull," which RLS makes false.)*
   - **User data** (notes, favorites, RSVP): two-way via an **outbox** with client-generated
     UUIDs; conflict policy per category — server-wins for content, **LWW + conflicted-copy**
     for notes (no silent loss), LWW for RSVP/favorites, append-only for focus logs.
   - **Payments: online-only, never queued.**

3. **One auth/RBAC model (migration `0001`).** Supabase custom-claims RBAC:
   `user_roles` + `role_permissions` tables → a **custom access-token hook** injects a
   `user_roles` array claim → a single `authorize(permission)` `SECURITY DEFINER` helper used in
   **every** RLS policy. Deny-by-default, RLS on every table. Roles: `super_admin`,
   `pastor_admin`, `finance`, `content_editor`, `member`, `anonymous`. Permissions:
   `hymns.manage`, `events.manage`, `media.manage`, `giving.read`, `giving.read_identity`,
   `roles.manage`, `schedule.manage`, `focus.manage`, `announcements.send`, …

4. **One money schema (frozen before the giving slice).** Table **`transactions`** (FK
   `profile_id` **NOT NULL**), category via the church-editable **`giving_categories`** lookup,
   one **`is_anonymous`** display flag, status enum incl. `refunded`/`reversed`,
   `authorization jsonb` (**token only — never card data**), `fees_pesewas`, `idempotency_key`,
   and **`pledge_installments`** for pledge schedules. **Money = integer pesewas** (GHS ×100),
   never floats. **Clients cannot write money tables** — only Edge Functions (service role) do,
   and status flips to `success` **only** on a signature-verified Paystack webhook +
   server-side re-verify. Immutable `financial_audit_log` (enforced in Postgres via
   REVOKE + trigger).

5. **Config/secrets.** Only the Supabase **anon key** + URL and the Paystack **public** key
   reach the client. Service-role key, Paystack secret, R2 keys, FCM service account live in
   Supabase Function secrets / GitHub Actions secrets — never in the app or repo.

6. **Honest limits are first-class** (not footnotes): focus mode can't trap users; the free
   project pauses; "anonymous" giving is a UI mask over attributed records; the Ghana Data
   Protection Act applies once PII/finance is stored.

---

## System overview

```
                 ┌──────────────── Flutter app (iOS/Android) ────────────────┐
                 │ Presentation (Riverpod + go_router)                       │
                 │   ↓ reads streams / writes local-first                    │
                 │ Repositories  → drift (SQLite, FTS5)  ← single source     │
                 │                   ▲  Sync engine (delta pull + tombstones │
                 │                   │  + outbox push)                       │
                 └───────────────────┼───────────────────────────────────────┘
                                     │ PostgREST / Realtime / Edge Functions
   React admin SPA ───────────────►  Supabase: Postgres (RLS) · Auth (anon→real, TOTP)
   (Cloudflare Pages)                 · Storage (images) · Edge Functions (Deno) · pg_cron
                                           │              │                 │
                               Cloudflare R2 (audio/     YouTube/Vimeo    FCM (push)
                               files, 0 egress)          (video links)    Paystack (webhook)
```

---

## Repo / monorepo structure

```
church-app/                     # existing empty repo (branch: claude/church-software-architecture-m2cr2n)
  pubspec.yaml                  # Dart pub workspace (apps/mobile + packages/shared)
  melos.yaml                    # cross-package analyze/test/format scripts
  apps/mobile/                  # Flutter app
    lib/
      main.dart                 # bootstrap: drift open → Supabase.init → ensure anon session → runApp
      app.dart                  # MaterialApp.router, themes, l10n
      core/                     # theme tokens, router+redirects, DI roots, drift AppDatabase,
                                #   sync engine, connectivity, error/Result, l10n, shared widgets
      features/
        hymnal/                 # v1 — domain/ data/ presentation/ (the triad every feature copies)
        settings/               # v1
        auth/ events/ media/ giving/ pledges/ notifications/ focus/ notes/ bible/   # later slices
    test/                       # mirrors lib/; golden tests for ordinary vs chorister
  packages/shared/              # Dart models, enums, DTOs (mobile-only)
  admin/                        # React+TS SPA (own package.json / pnpm) — NOT a Dart package
  supabase/
    config.toml                 # anonymous sign-in enabled; webhook fn verify_jwt=false
    migrations/                 # 0001_auth_core, 0002_hymnal, 0003_events…, forward-only SQL
    functions/                  # _shared/, health (keepalive), r2-sign-*, paystack-*, notifications-dispatch
    seed.sql                    # default church, sample hymns (both views), one user per role
  .github/workflows/            # ci.yml, keepalive.yml, backup.yml, migrations-deploy.yml, admin-deploy.yml
  docs/                         # decision records (money schema, RBAC, sync) + this plan's living copy
```

Every feature module repeats the identical `domain / data / presentation` triad; `core/` never
imports `features/`. Adding a release = adding a feature folder + registering its route/tab
(driven by a synced `feature_flags` table, so modules can dark-launch without a store release).

---

## Release roadmap

| Version | Scope | Notes |
|---|---|---|
| **1.0.0** | **Hymnal, offline-first** | The build target of this plan. See DoD below. |
| 1.1.0 | Events, schedule, programs (+ RSVP) | First two-way sync (outbox) on low-stakes RSVP |
| 1.2.0 | Media (sermons/devotionals/audio/video) | R2 audio + YouTube video; `r2-sign-*` functions |
| 1.3.0 | Accounts + **Giving** (online-only) | anon→real upgrade; Paystack; **gated** — see cost/ops |
| 1.4.0 | Pledges + campaigns (reminders-only) | local reminders + money dashboard |
| 1.5.0 | Notifications + **cooperative focus** | FCM + local notifications; focus logging |
| 1.6.0 | Notes + linking | polymorphic note→material links; conflicted-copy sync |
| 1.7.0 | Bible (public-domain KJV/WEB) + geofence (foreground, when-in-use) | bundle ~4–5 MB into drift |
| 2.0.0 | reserved | breaking change: mandatory phone verification / major redesign |

**Versioning:** strict SemVer (so "add events" is a **minor** `1.1.0`, not `1.0.1`) + a
monotonic store **build number**. Owner may prefer marketing-style bumps — fine; the only hard
rule is the store build number must always increase.

**Focus mode — informed by the "Grit"/app-blocker question:** apps that appear to "lock" you
(Opal, one sec, Focus Bear) ride Apple's **Screen Time / Family Controls** API (iOS) or
Accessibility + overlay (Android) — all **user-authorized and user-revocable self-control
tools**; none lets a third party (the church) trap a member's phone, and habit apps like Grit
don't block at all. So v1.5.0 focus stays **cooperative** (worship UI + leave-logging). A later
**opt-in "assisted focus"** (member chooses to shield distracting apps during service via the
Screen Time API / `flutter_family_controls`) is a possible future add — it carries an Apple
entitlement + extra review and is **not** in the core roadmap.

---

## v1.0.0 — Hymnal scope & Definition of Done

**In scope:** browse/search hymns fully offline; ordinary↔chorister toggle; admin manages
hymns. **No accounts, no payments, no push** — just the offline hymnal + the admin that feeds it.

Done when:
- App shows the **full hymnal with zero network** (airplane mode, fresh install) from a baked-in
  seed; no spinner ever gates read content on the network.
- Browsing is **anonymous**: boot creates/restores a Supabase anonymous session; no login screen.
- Each hymn renders full metadata: number, title, first line, author, composer, tune, meter,
  musical key, scripture ref, language, category/theme.
- **Ordinary↔chorister** toggles instantly & offline over already-loaded data (chorister adds
  the cached **sheet-music PDF**, rendered offline via `pdfx`, + notation metadata +
  annotations); persisted global default + per-hymn override.
- **FTS5 search** by number/title/first-line/author, offline, snappy on a low-end Android phone.
- Readability: user text-scale slider (independent of OS), wakelock on hymn screens, large/
  high-contrast preset.
- Delta sync runs on launch/resume/connectivity/pull-to-refresh, applies `updated_at` upserts +
  a **tombstone sweep**, updates the cursor from server timestamps only; paused/offline/5xx
  no-ops and retries with a subtle "last synced" indicator.
- **React admin** (on Cloudflare Pages): a non-technical staffer can create/edit a hymn (both
  views), upload a sheet-music **PDF**, preview both views, publish; changes reach devices on
  next sync; soft-delete propagates and purges on-device via tombstones.
- **RLS verified by pgTAP**: anon/members read only published non-deleted content; only
  `hymns.manage` can write; canonical access-token hook + `authorize()` in place.
- **External keepalive cron** + **nightly `pg_dump`→R2 backup** proven working (built now so the
  project never pauses and data is recoverable before any later slice adds irreplaceable data).
- Material 3 seeded theme (light/dark via tokens, no raw hex); gen-l10n scaffolded (English
  complete; empty Twi/Ewe/Ga ARBs); content language is filterable data, decoupled from UI locale.
- **CI green gate**: `flutter analyze` + format + tests (incl. ordinary-vs-chorister golden
  tests), `supabase db reset` + pgTAP, and a schema→generated-types drift check.
- Platform decision recorded (Android-only vs iOS) and app builds/installs on the chosen target.

---

## Implementation steps (v1)

1. **Commit 3 decision records to `/docs`** (resolve the seams the review found): the canonical
   money schema, the one RBAC model, and tombstones as the single deletion mechanism; pin
   **drift** as the sole client DB.
2. **Scaffold the monorepo** on the existing branch: root `pubspec.yaml` (pub workspaces) +
   `melos.yaml`; `apps/mobile` (`flutter create`), `packages/shared`, `admin` (Vite React+TS),
   `supabase/`, `.github/workflows/`, `docs/`; `.gitignore` (`.env`, build dirs). First commit.
3. **Supabase local + migration `0001`** (`supabase init/start`): extensions
   (`pgcrypto`/`pg_trgm`/`citext`); `church` + `profiles`; `user_roles` + `role_permissions` +
   `custom_access_token_hook` + `authorize()`; `set_updated_at()` trigger; soft-delete→
   `tombstones` trigger + public `tombstones` table; deny-by-default RLS; enable anonymous
   sign-in in `config.toml`.
4. **Migration `0002` (hymnal):** `hymns`, `hymn_sections`, `hymn_categories`, `hymn_assets`
   with `id/created_at/updated_at/deleted_at/published`, `search_vector` + GIN index, public-read
   RLS on published rows. `seed.sql` with sample hymns (both views) + one user per role.
5. **Flutter spine:** `main.dart` bootstrap; `core/` (theme tokens; go_router shell with
   Hymns+Settings; Riverpod DI roots; drift `AppDatabase` with hymn tables + FTS5 +
   `sync_cursors` + `kv_settings` + `tombstones`; `Result`/`AppFailure`; l10n);
   `features/hymnal/` in the domain/data/presentation triad. Pin the package set (riverpod,
   freezed, go_router, supabase_flutter, drift + sqlite3_flutter_libs, cached_network_image,
   **pdfx** for offline sheet-music PDFs, wakelock_plus, connectivity_plus); set up
   `dart run build_runner`.
6. **Sync engine as a table registry** (`SyncableTable` config per table): delta pull +
   tombstone sweep driven by connectivity/lifecycle/pull-to-refresh. Verify hymnal renders from
   seed offline, then tops up from Supabase online.
7. **React admin** (react-admin + ra-supabase): hymn CRUD + sheet-music upload to Supabase
   Storage + preview of both views; `supabase-js` auth with an `authorize`-based route guard;
   deploy to Cloudflare Pages.
8. **Ops + CI from day one:** `health` Edge Function + external keepalive cron; nightly
   `pg_dump`→(gpg)→private R2 backup; `ci.yml` (analyze/format/test incl. goldens, `db reset` +
   pgTAP, types-drift check); branch protection requiring green CI.

---

## Honest cost model & operational must-dos

- **"Free" is true for an Android-only, pre-giving hymnal.** Real costs to budget from day one:
  **Apple Developer $99/yr** (required for iOS builds *and* push), **Google Play $25 one-time**,
  **Paystack ~2%/txn**, **Ghana DPC registration fee**, and **Supabase Pro ~$25/mo once giving
  launches** (free tier has no backups and *will* pause — unacceptable for financial data).
- **The free project pauses after ~7 days idle.** An internal `pg_cron` **cannot** keep its own
  project awake (a paused Postgres stops cron too). An **external** daily ping (GitHub Actions /
  cron-job.org) to a `health` function is **mandatory infrastructure**, shipped in v1.
- **Payments truth = server-side `/transaction/verify` + reconcile cron**, not the webhook alone
  (a paused project or missed delivery must still be recoverable). MoMo confirms asynchronously —
  the client shows "pending," never "success."
- **Ghana Data Protection Act (Act 843):** register as a **Data Controller**, publish a privacy
  notice, capture consent (incl. cross-border-transfer disclosure — Supabase/Cloudflare/Paystack
  are offshore), set a retention/erasure policy (anonymize gift rows, don't hard-delete). A
  **hard precondition of the giving slice**, not a later note.
- **"Anonymous" giving is a UI mask** over attributed records (needed for receipts/tax/
  reconciliation); a finance admin with `giving.read_identity` can unmask (audited). This must be
  told to the church in writing so expectations are honest.
- **Account recovery:** phone is unverified and email optional, so there's no reset path for a
  bare phone+password account. Require **one verifiable channel at the anon→real upgrade**
  (capture email — also needed for Paystack/receipts — or verify phone once) so members with
  giving history can't be locked out.

---

## Config & secrets strategy

Each tool gets the config mechanism it's happiest with; **only public values ever reach a
client**, real secrets live in managed secret stores.

- **Flutter app → JSON** via `--dart-define-from-file=config/<env>.json` (Flutter's native,
  CI/Codemagic-friendly way). Holds only **public** values: Supabase URL + **anon** key, Paystack
  **public** key. Files: `config/dev.json`, `config/prod.json` (git-ignored; a committed
  `config/example.json` documents the keys).
- **React admin → `.env`** (Vite convention, `VITE_`-prefixed, also public-only).
- **Supabase (Edge Functions / CLI) → `supabase secrets set`** + a local git-ignored `.env`.
  This is where true secrets live: service-role key, Paystack **secret** key + webhook secret,
  R2 keys, FCM service account.
- **GitHub Actions → repository secrets** for CI/deploy (DB password, Supabase access token, R2
  creds for backups).
- **This cloud build session:** you *can* provide secrets to the container — add them in the
  **environment settings** (the cloud-environment menu in the session title bar → Edit → API
  credentials / environment variables); a new session picks them up, and I'll tell you the exact
  variable names when we need them. I'll never ask you to paste a key into the chat.

So: **both** — JSON for the app, `.env` for the web admin and backend tooling — and the decision
record in `/docs` will pin exactly which key goes where.

## Church profile model (yes — it's a first-class, editable entity)

A `church` row is a real model, seeded in migration `0001`, that admins edit in a **Church
Profile** screen. Fields: `name`, `logo_path`, `banner_path`, `about`, contact `email` + `phone`
+ `address`, `website`, **`socials jsonb`** (facebook/instagram/youtube/whatsapp/x/tiktok…),
`service_times` (from the schedule), `currency` (GHS), `timezone` (Africa/Accra), and a
free-form `settings jsonb` for future toggles. The app syncs and caches it offline for branding
(logo/colors), an About/Contact screen, and social links.

**Multi-tenancy call (resolving a review flag):** we run a **single church** = one `church` row
used as an editable **profile/settings singleton**. We will **not** thread `church_id` through
every table in v1 (that overhead buys nothing for one church, and half-applying it is the worst
option). True multi-tenant / white-label becomes a dedicated future migration if ever needed.

> **Update (ADR 0007):** the product is now white-label without multi-tenancy: one codebase,
> built and deployed separately for each church, each with its own Supabase project. The
> single-church model above holds within each deployment. See
> [`decisions/0007-white-label-builds.md`](decisions/0007-white-label-builds.md).

## Decision-making protocol (you stay in control)

To answer "will an agent assume things for me?": **no silent assumptions.** Decisions are sorted
into two buckets, and everything is written down.

- **Always comes to you** (I stop and ask): anything touching **money/cost**, **security/
  privacy/legal** (e.g. Ghana DPA), **user-facing UX & branding**, **third-party service
  choices**, **data-model shapes that are hard to reverse**, and **scope/roadmap** changes.
- **I pick a sensible default + tell you** (you can veto anytime): library/package versions,
  file & folder naming, code style, minor internal UX, test layout, and other low-stakes,
  reversible, conventional choices.
- **Everything is logged.** A running **Decision Log** in `/docs/decisions/` records every
  choice and assumption with a one-line rationale, so nothing is hidden and you can reverse any
  of them. The **Canonical architecture decisions** above are frozen precisely so that I — and
  any helper agents I run — build against one agreed design and don't drift or re-invent.

## Decisions status

**Locked (this round):** both iOS + Android · English UI with Ghanaian hymn-content uploads ·
sheet music = public PDF, visible to everyone, offline-rendered · church is an editable model ·
single-church (no multi-tenant plumbing in v1) · config via JSON (app) + `.env` (admin/backend).

**Still open — but none block starting v1 (needed later, mostly by the giving slice):**
- Which registered legal entity + GHS bank account Paystack settles to (gates giving; Paystack
  "Starter" can begin collecting up to ~GHS 30k with just an owner ID while registration is in
  progress — confirm current cap/fees live before launch).
- Whether to budget Supabase Pro (~$25/mo) to coincide with the giving slice (backups + no pause).
- Daily-devotional / notification cadence defaults (decided when we reach v1.5.0).

---

## Verification (how we'll prove v1 works end-to-end)

1. **Offline-first proof:** fresh install → airplane mode → full hymnal browses & searches from
   seed, ordinary/chorister toggle works, no error walls.
2. **Sync proof:** online → admin edits a hymn & uploads sheet music → pull-to-refresh on device
   → change appears; admin soft-deletes a hymn → it disappears on device after a tombstone sweep.
3. **Security proof:** `supabase test db` (pgTAP) — anon/member read only published content;
   non-`hymns.manage` user cannot write; a member cannot read another's rows.
4. **Resilience proof:** simulate a paused/5xx backend → app still serves the hymnal and shows
   "syncing…/last synced," never an error; `health` keepalive cron run is green; a `pg_dump`
   backup artifact exists and restores into a scratch DB.
5. **Quality gate:** `melos run analyze && melos run test` (incl. ordinary-vs-chorister golden
   tests) and the types-drift check all green in CI before merge.
6. **Real-device smoke:** install the built APK (and iOS build if chosen) on a low-end phone;
   confirm search latency and readability (text scale, wakelock) are acceptable.
