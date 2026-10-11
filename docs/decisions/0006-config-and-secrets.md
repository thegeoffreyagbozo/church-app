# ADR 0006 — Config: JSON for the app, `.env` for admin/backend; secrets never in clients

**Status:** Accepted · **Date:** 2026-10-11

## Context
Three toolchains (Flutter app, React admin, Supabase/Edge + CI) each have idiomatic config
mechanisms. We need one clear rule for where each value lives, and a hard line on secrets.

## Decision
- **Flutter app → JSON** via `--dart-define-from-file=config/<env>.json`. Holds **public-only**
  values: Supabase URL + **anon** key, Paystack **public** key. `config/dev.json` and
  `config/prod.json` are git-ignored; `config/example.json` is committed as documentation.
- **React admin → `.env`** (Vite, `VITE_`-prefixed, public-only).
- **Supabase Edge Functions / CLI → `supabase secrets set`** + a local git-ignored `.env`. This
  is the only place true secrets live: service-role key, Paystack **secret** + webhook secret,
  R2 keys, FCM service-account JSON.
- **GitHub Actions → repository secrets** (DB password, Supabase access token, R2 backup creds).
- **This cloud build container:** secrets are added in the **environment settings** (cloud-env
  menu → Edit → API credentials / environment variables); a new session picks them up. Keys are
  never pasted into chat.

## Hard rule
The only key a client (mobile or admin) ever holds is a **public** key (Supabase anon, Paystack
public) — safe because RLS enforces access server-side. The **service-role key is used only in
Edge Functions** and never shipped to a client or committed.

## Consequences
- `.gitignore` must exclude `config/dev.json`, `config/prod.json`, all `.env*` (except
  `*.example`), and build dirs.
