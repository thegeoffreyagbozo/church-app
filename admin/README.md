# admin — Church admin panel (React + TypeScript)

A web panel for non-technical church staff to manage content: hymns (ordinary + chorister),
sheet-music PDFs, events, media, pledge campaigns, the money dashboard, the church profile, and
roles. Built as a **Vite + React + TypeScript SPA** using **react-admin + ra-supabase**, deployed
to **Cloudflare Pages**. It talks to Supabase directly under RLS — no bespoke write API — and
derives its types from the database via `supabase gen types typescript`.

> **Status:** scaffolded in Implementation Step 7 of [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).
> This is **not** a Dart package and is not part of the pub workspace; it has its own
> `package.json` (pnpm).

## Setup (once scaffolded)

```bash
cd admin
pnpm install
cp .env.example .env            # VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY (public only)
pnpm dev
```

Access is gated by the `authorize(...)` RBAC model — see
[`../docs/decisions/0003-auth-and-rbac.md`](../docs/decisions/0003-auth-and-rbac.md).
