# supabase — backend (Postgres + Auth + Storage + Edge Functions)

Schema-first: the database is the single source of truth; the mobile app and admin derive their
types from it. All access is enforced by **RLS** (deny-by-default). Canonical rules:
[`../docs/decisions`](../docs/decisions).

## Layout

```
config.toml              anonymous sign-in, access-token hook, per-function verify_jwt
migrations/
  0001_auth_core.sql     extensions, RBAC (user_roles/role_permissions/authorize/hook),
                         church singleton, profiles, set_updated_at, tombstones
  0002_hymnal.sql        hymnals, categories, hymns, sections, assets, FTS, storage bucket
  0003_privileges_hardening.sql
                         service-role grants, explicit client grants, function hardening
  0004_readings.sql      readings + reading_parts (responsive readings, creeds, covenants)
seed.sql                 sample public-domain hymns and readings (dev/CI)
functions/
  health/                public keepalive endpoint (DB touch) — pinged by CI daily
.env.example             Edge Function secret names (copy → supabase/.env, git-ignored)
```

## Common commands

```bash
# Local stack (needs Docker):
supabase start
supabase db reset            # drops, applies all migrations, runs seed.sql
supabase functions serve health

# Cloud project:
supabase link --project-ref <ref>
supabase db push             # apply migrations (does NOT run seed.sql)
supabase functions deploy health
supabase secrets set --env-file supabase/.env

# Enable the access-token hook (once) in Dashboard → Authentication → Hooks, or it is
# picked up from config.toml on local. It injects `user_roles` into the JWT (ADR 0003).
```

## Sync contract (what the app relies on — ADR 0002)

Every syncable table has `id uuid`, `created_at`, `updated_at` (trigger-maintained), and
`deleted_at`. Clients pull `updated_at=gte.<cursor>` for upserts and sweep `tombstones` for
deletions. **Never hard-delete** a syncable row — set `deleted_at` (the trigger records a
tombstone and bumps `updated_at`).

## Verifying RLS (planned)

`supabase test db` with pgTAP (added in CI): anon & members read only `published`, non-deleted
content; only a holder of `hymns.manage` can write; a user cannot read another user's rows.
