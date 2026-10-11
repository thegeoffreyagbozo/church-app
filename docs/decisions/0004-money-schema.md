# ADR 0004 — One canonical money schema; server-authoritative; integer pesewas

**Status:** Accepted · **Date:** 2026-10-11 · **Slice:** v1.3.0 (giving) — frozen now so the
schema is stable; built later.

## Context
Three design passes named the giving ledger three incompatible ways (`transactions` /
`payment_transactions` / `gifts`) with divergent columns, status enums, and pledge sub-tables.
Money code (Edge Functions, RLS, dashboard, client) cannot compile against three shapes.

## Decision
One frozen schema, owned by the backend domain:

- Ledger table **`transactions`** with FK **`profile_id` NOT NULL** (giving is always attributed).
- Category via the church-editable **`giving_categories`** lookup (not a fixed enum), seeded
  `offering`, `tithe`, `donation`.
- One **`is_anonymous`** flag — a **display mask only**; `profile_id` is always stored.
- `status` enum incl. `initialized, pending, success, failed, abandoned, reversed, refunded`.
- `authorization jsonb` stores **tokens only (never card PAN/CVV)**; `fees_pesewas`;
  `idempotency_key` (unique); unique `processor_reference`.
- Pledges via **`pledges`** + **`pledge_installments`** (the richer installment model);
  `giving_campaigns` with target + start/end. **Reminders-only — no auto-charge.**
- **Money is integer pesewas** (`bigint`, GHS ×100) everywhere — never floats.
- **`financial_audit_log`** is append-only, **immutability enforced in Postgres**
  (`REVOKE UPDATE, DELETE` + a `BEFORE UPDATE OR DELETE` trigger).

## Authority & integrity
- **Clients cannot write money tables.** Only Edge Functions (service role) write them.
- Status flips to `success` **only** on a signature-verified Paystack webhook (HMAC-SHA512 over
  the raw body, constant-time) **plus** a server-side `/transaction/verify`; the verified amount
  must equal the stored amount. MoMo confirms async → the client shows `pending`, never success.
- Idempotency via unique `reference` + `dedupe_key = sha256(raw_body)`; retries create a new row.
- Backstops for a missed webhook (free-tier pause): client `giving-verify` poll + a
  `giving-reconcile` cron; verify-on-read is the ultimate truth.

## Consequences
- Anonymity is honestly a UI mask (a `giving.read_identity` holder can unmask, audited) — the
  church must be told in writing that records are always attributed for tax/reconciliation.
- Giving requires a registered settlement entity + GHS account (or Paystack "Starter") and is
  gated by Ghana DPA registration.
