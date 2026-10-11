# ADR 0002 — One sync model; deletions via a public `tombstones` table

**Status:** Accepted · **Date:** 2026-10-11

## Context
Independent design passes disagreed on how deletions propagate to offline devices. Content RLS
filters rows to `published = true AND deleted_at IS NULL`, so a soft-deleted or unpublished row
simply **stops appearing** in a normal `updated_at > cursor` delta pull — the client would never
learn to purge it, and the deleted hymn would live on devices forever.

## Decision
One sync model for the whole app:

- **Read content** (hymns, events, media, bible): one-way **delta pull** —
  `GET ...?updated_at=gte.<cursor>&order=updated_at.asc,id.asc`, idempotent **upsert keyed on
  `id`**. The cursor is the max **server** `updated_at` received (never the device clock); `gte`
  + idempotent upsert tolerate same-millisecond boundaries.
- **Deletions:** a soft-delete trigger writes `{table_name, row_id, deleted_at}` to a
  **publicly-readable `tombstones` table** (no payload → no RLS leak). Each sync does a second
  sweep: `GET tombstones?deleted_at=gte.<cursor>` and deletes those rows locally.
- **User data** (notes, favorites, RSVP): two-way via an **outbox** with **client-generated
  UUIDs** (idempotent retries). Conflict policy by category: server-wins for content;
  **LWW + conflicted-copy** for notes (never lose text); LWW for RSVP/favorites; append-only
  for focus logs.
- **Payments: online-only, never queued.**

## Consequences
- Every syncable table needs `id`, `created_at`, `updated_at` (trigger-maintained), `deleted_at`.
- Tombstones need a retention window (default **180 days**); a device offline longer does a full
  re-sync. Old tombstones are purged server-side after the window.

## Alternatives rejected
- "Deleted rows come back in the main pull" — **false** under the content RLS filter above.
- A bespoke `sync-pull` Edge Function — unnecessary; PostgREST + tombstones suffice.
