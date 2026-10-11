# ADR 0001 — drift (SQLite) is the sole on-device database

**Status:** Accepted · **Date:** 2026-10-11

## Context
The app is **offline-first**: the hymnal (and all read content) must work with no connection,
and the UI must never block on the network. Several domains (hymnal, sync outbox, focus logs,
notes) all need the *same* local store, so it must be pinned once.

## Decision
Use **drift** (SQLite) as the single local database the UI reads from. The UI reads reactive
drift streams; writes go local-first. Every other on-device table (sync cursors, outbox, focus
events, kv settings) lives in this one drift database owned by the hymnal/core layer.

## Why
- Hymnal data is **relational** (hymn → sections → assets → categories) — SQL joins fit.
- **FTS5** gives fast offline search by number/title/first-line/author with no extra engine.
- Mature **versioned migrations** — essential because the schema grows every release slice.
- Reactive `.watch()` streams integrate cleanly with Riverpod `StreamProvider`.
- SQL semantics mirror Supabase Postgres, making delta-sync reasoning straightforward.

## Consequences
- Large binaries (sheet-music PDFs, audio) are stored as **files on disk**; only paths/metadata
  go in SQLite.
- Codegen (`drift_dev` + `build_runner`) is part of the toolchain.

## Alternatives rejected
- **Isar** — serious maintenance uncertainty.
- **Hive** — key-value only; too weak for relational hymn metadata.
- **ObjectBox** — good objects, but its sync is a paid feature and we already have Supabase.
