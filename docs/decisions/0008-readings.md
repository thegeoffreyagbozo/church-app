# ADR 0008: Readings, one model for responsive readings, creeds, covenants and benedictions

**Status:** Accepted · **Date:** 2026-10-11 · **Slice:** v1.0.0, alongside the hymnal

## Context
Hymn books hold more than hymns: responsive readings (leader and congregation alternate, the
congregation's lines printed in bold), entries such as "Calls to Worship" and "Benedictions"
that collect several numbered passages with their own scripture references, creeds, and the
church covenant read together at communion. None of these are hymns: they have no tune, meter,
key or verses, and they must not appear in hymn numbering, hymn search or the chorister view.
They are read aloud in services, so they must work offline exactly like hymns.

## Decision
- **Two tables, mirroring `hymns` and `hymn_sections`:**
  - `readings`: kind, optional number, title, scripture reference, language, copyright fields,
    sort order and published flag, plus the sync columns (ADR 0002).
  - `reading_parts`: the ordered parts of a reading. Each has an optional speaker (`leader`,
    `people` or `all`), an optional item number, its text (`body`) and an optional scripture
    reference.
- **Kinds:** `responsive_reading`, `call_to_worship`, `benediction`, `creed`, `covenant`
  (Postgres enum `reading_kind`). A new kind is a one-line migration plus app support.
- **A collection is one reading with numbered parts.** A book's "Benedictions" entry is one
  reading of kind `benediction` whose parts are numbered 1 to n, each with its own reference.
- **Numbering:** reading numbers are unique per language and separate from hymn numbers.
  Creeds and covenants are usually unnumbered.
- **Text:** a part's body may contain line breaks, `- ` bullet lines and `**bold**` emphasis,
  which the app renders. Nothing else (no HTML).
- **Access:** public read when published and not deleted (parts follow their reading); writes
  need `hymns.manage`, so the people who manage hymns also manage readings.
- **Sync:** both tables carry the sync spine (`updated_at` trigger, tombstone on soft delete)
  and join the client's sync registry.
- **Hymn numbering series:** a book's separately numbered parts (main hymns, supplementary hymns
  that restart at 1, unnumbered service music) become separate `hymnals` rows, because hymn
  numbers are unique per hymnal. The hymn tables need no change.

## Consequences
- The app gets a Readings section beside Hymns, browsable and searchable offline; responsive
  readings show the congregation's lines in bold.
- The admin panel needs a readings editor (parts with speaker, item number and reference).
- The content importer loads hymns and readings from the same transcription format.

## Alternatives rejected
- **Storing readings as hymns.** Breaks hymn numbering and search, and has nowhere to record
  who reads each line.
- **One table per kind (covenant, creed, and so on).** The same shape five times over, each
  needing its own sync, RLS and admin screens.
- **PDF only.** Doesn't reflow on a phone, ignores the app's text size, and can't be searched.
