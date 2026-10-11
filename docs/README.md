# Docs

This folder is the project's single source of truth for **why** things are built the way they
are. Code can be read anywhere; the reasoning lives here.

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** — the full, approved architecture & build plan
  (product decisions, tech stack, roadmap, v1 Definition of Done, cost model, verification).
- **[decisions/](./decisions/)** — the Decision Log: one short record (ADR) per significant
  choice, with its rationale, so nothing is assumed silently and any choice can be revisited.

## How decisions are made (the protocol)

- **Always brought to the owner** before acting: anything touching money/cost, security/privacy/
  legal (e.g. the Ghana Data Protection Act), user-facing UX & branding, third-party service
  choices, hard-to-reverse data shapes, or scope/roadmap.
- **Default-and-tell** (owner can veto anytime): library/package versions, file & folder naming,
  code style, minor internal UX, test layout, and other low-stakes, reversible choices.
- **Everything is logged** here as an ADR, newest numbers appended. The "Canonical architecture
  decisions" (ADRs 0001–0006) are **frozen** so the app — and any helper agents — build against
  one agreed design instead of drifting.

## ADR index

| # | Decision | Status |
|---|----------|--------|
| [0001](./decisions/0001-local-db-drift.md) | drift (SQLite) is the sole on-device database | Accepted |
| [0002](./decisions/0002-sync-model-and-tombstones.md) | One sync model; deletions via a public `tombstones` table | Accepted |
| [0003](./decisions/0003-auth-and-rbac.md) | One auth/RBAC model: `user_roles` + `authorize()` + access-token hook | Accepted |
| [0004](./decisions/0004-money-schema.md) | One canonical money schema; server-authoritative; integer pesewas | Accepted |
| [0005](./decisions/0005-single-church-no-multitenancy.md) | Single-church profile singleton; no multi-tenant plumbing in v1 | Accepted |
| [0006](./decisions/0006-config-and-secrets.md) | Config: JSON for the app, `.env` for admin/backend; secrets never in clients | Accepted |

To add a decision: copy the format of any ADR, give it the next number, and add a row above.
