# ADR 0003 — One auth/RBAC model: `user_roles` + `authorize()` + access-token hook

**Status:** Accepted · **Date:** 2026-10-11

## Context
RLS is the most cross-cutting surface in the system, yet independent design passes assumed four
different role vocabularies and two JWT claim shapes. These must be reconciled **before** any
policy ships (migration `0001`), or every later slice re-litigates auth.

## Decision
Adopt one permission-based RBAC model:

- Tables **`user_roles`** (user_id, role) and **`role_permissions`** (role, permission) —
  multi-role capable.
- A **custom access-token hook** (`public.custom_access_token_hook`) injects a `user_roles`
  array claim into the JWT on every login/refresh.
- A single **`authorize(app_permission)`** `SECURITY DEFINER` helper reads the JWT claim (no
  table read inside policies → no recursion, fast). Every RLS policy calls `authorize(...)`.
- **Deny-by-default:** RLS enabled on every table; no policy = no access.

**Roles:** `super_admin`, `pastor_admin`, `finance`, `content_editor`, `member`, `anonymous`.
**Permissions (extensible):** `hymns.manage`, `events.manage`, `media.manage`, `giving.read`,
`giving.read_identity`, `roles.manage`, `schedule.manage`, `focus.manage`, `announcements.send`.

## Identity
Profile = name + phone (email optional). **Anonymous** browsing by default (Supabase anonymous
sign-in; no `profiles` row for anon). Account required only for giving/pledges/notes-sync, via an
**anonymous → real** upgrade that preserves the same `auth.uid()`. Login = phone + password +
**optional TOTP 2FA** (authenticator app, **no SMS**). Phone stays unverified until the giving
slice; **one verifiable recovery channel** (email, or one-time phone verification) is captured at
the anon→real upgrade so members with giving history can't be locked out.

## Consequences
- Helpers `is_staff()` / `is_admin()`, if used in prose, are thin wrappers over `authorize()`.
- Role changes go through an admin path so the JWT claim stays consistent.

## Alternatives rejected
- A singular `role` enum claim + per-table `is_staff()` reads — not multi-role; risks RLS
  recursion.
- SMS OTP as first/second factor — avoided for cost; TOTP is free.
