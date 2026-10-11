# ADR 0005 — Single-church profile singleton; no multi-tenant plumbing in v1

**Status:** Accepted · **Date:** 2026-10-11

## Context
One design pass proposed `church_id` on nearly every table for future multi-tenancy; others
omitted it on money/RBAC/notification tables. Half-applied tenant scoping is the worst of both
worlds (overhead without the guarantee), and the product is a **single church** today.

## Decision
- Keep **one `church` row** as an editable **profile/settings singleton**, seeded in migration
  `0001`. It is a first-class, admin-editable model: `name`, `logo_path`, `banner_path`, `about`,
  `email`, `phone`, `address`, `website`, **`socials jsonb`**, `currency` (GHS), `timezone`
  (Africa/Accra), `settings jsonb`. The app syncs & caches it for branding + an About/Contact
  screen + social links.
- **Do not** thread `church_id` through other tables in v1.
- True multi-tenant / white-label, if ever wanted, becomes a **dedicated future migration** —
  not an obligation paid now.

## Consequences
- Simpler RLS and schema for v1.
- A future multi-tenant migration would add `church_id` + tenant-scoped policies in one deliberate
  pass, rather than retrofitting inconsistent columns.
