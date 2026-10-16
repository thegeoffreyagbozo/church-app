# ADR 0009: The reading experience (piece 1 of the app)

**Status:** Accepted · **Date:** 2026-10-12 · **Builds on:** [ADR 0001](./0001-local-db-drift.md),
[ADR 0007](./0007-white-label-builds.md), [ADR 0008](./0008-readings.md) · **Amended by:**
[ADR 0010](./0010-platform-tab-bars.md)

## Context
A congregation needs its hymn book and readings in the pew: found within seconds of the number
or first line being announced, readable in a dim church, on low-end Android phones, with or
without data. Each church brands its own build (ADR 0007), so the design has to work with any
church's colours.

## Decision
- **The "Hymnal" style.** Warm paper, Literata for text and titles, Fraunces for numbers, Inter
  for labels, and Atkinson Hyperlegible as an extra-legible option. The fonts are bundled with
  their SIL Open Font License texts and never fetched.
- **Two brand colours from the church settings file**: `BRAND_PRIMARY` and `BRAND_ACCENT`
  (ADR 0007). The Paper and Night palettes are derived from them, and each text colour is
  darkened or lightened until it meets WCAG AA, so any brand colours work.
- **Glass only where it helps**: the pinned header, the `···` menu and sheets, drawn with
  Flutter's blur (the tab bar is each platform's own since
  [ADR 0010](./0010-platform-tab-bars.md)). It turns solid on Android phones with 3 GB of RAM or
  less (or that report low memory) and when the phone asks for high contrast.
- **One search bar, no Search tab.** It takes digits, a section and a number ("S2", "hymn 268"),
  a scripture reference or words, offline (SQLite FTS5). The app draws its own number row above
  the keyboard, because Android apps cannot turn on the keyboard's. Go opens the top result once
  the results for everything typed are in.
- **Hymn pages have no bottom bar and no swiping.** The chorus repeats after every verse; a
  Words / Music switch and a `···` menu sit at the top; the next hymn is found through search.
- **Readings show two unlabelled voices**: plain, and bold on a soft band. The conductor decides
  who reads which. Creeds and covenants say "Everyone reads together".
- **The content ships as a complete SQLite database.** `packages/content_db` builds it from a
  church's Supabase project through the public API (publishable key), and the app installs it
  on first launch. A newer bundle replaces the content and keeps the phone's settings and
  recently opened list. The same package holds the schema, the queries and the search, so the
  bundled file always matches the app.

## Consequences
- The app works with no network from its first launch. Until sync (piece 2), content changes
  reach phones with an app update.
- Church content never enters this public repository: bundled databases are built locally
  (git-ignored) and CI uses a public-domain sample.
- `sqlite3` now bundles SQLite itself through build hooks; `sqlite3_flutter_libs` is retired and
  not used.

## Alternatives rejected
- **A Search tab or a separate number pad:** an extra tap before typing, and less familiar than
  the search bar every app has.
- **Swiping between hymns:** hymns are not sung in book order, and a stray swipe mid-song would
  change the page.
- **Leader / People labels on readings:** churches split the voices differently.
- **Fetching Google Fonts at runtime:** breaks offline use and sends reader data to a third party.
- **Seeding the phone from JSON on first launch:** slower than copying a ready database, and the
  search index would be built on the phone.
