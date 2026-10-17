# content_import

Turns a hymn book transcribed into plain text (hymns, responsive readings, creeds, the church
covenant) into one SQL script that loads it into a church's Supabase project (ADR 0008).

## Run it

```bash
cd packages/content_import
dart run content_import ~/Documents/<church>/transcribed/*.txt --out ~/Documents/<church>/import.sql

# then, from the repo root, linked to that church's project:
supabase db query --linked -f ~/Documents/<church>/import.sql
```

- Import **every** batch file in one run, in book order: unnumbered pieces are ordered by where
  they appear.
- Nothing is written if any file has an error; each error names the file and line to fix.
- Running it again after a correction updates the same rows, because ids come from the section
  and number (or the kind and title). Renaming an unnumbered piece creates a new row instead.
- A hymn is published only when every printed credit is public domain (life + 70 years, as in
  Ghana) or a `Copyright: public domain` label says so; the summary lists the rest.
  `--publish-all` overrides this for development only. `Status: draft` items are never
  published.
- Real church content and the generated SQL stay outside this public repo (ADR 0007).

## Format

`test/fixtures/sample_book.txt` is a complete example. Lines starting with `#` are notes.

| Line | Meaning |
|---|---|
| `SECTION <name>` | Starts a numbering series (Hymns, Supplementary Hymns, Service Music). |
| `TOPIC <name>` | Topic of the hymns that follow, until the next `TOPIC` or `SECTION`. |
| `GROUP <part> / <subheading>` | The book's contents heading of the hymns that follow, in the current section, until the next `GROUP`, `TOPIC` or `SECTION`. A part without subheadings is just `GROUP <part>`. The app shows these as headings in the section list. |
| `HYMN <number>` | A hymn; leave the number off for unnumbered pieces. |
| `READING <number>` | A responsive reading. |
| `CREED`, `COVENANT` | Unnumbered readings. |
| `Label: value` | Right after the item line: `Title` (required), `Tune`, `Words`, `Music`, `Arranged`, `Translated`, `Scripture`, `Also sung to`, `Meter`, `Key`, `Copyright`, `Status: draft`; readings also take `Kind` (calls to worship, benedictions) and `Read by` (Leader, People, All). |
| a lone number | Starts that verse. `CHORUS` or `REFRAIN` starts the chorus. |
| `Leader:` `People:` `All:` | Who reads a line of a reading. |
| `1.` | Numbers an item in a collection, such as one benediction. |
| `Ref: ...` | Scripture reference of the line or item above. |
| `- ...` | A bullet inside the item above. `**bold**` is kept for emphasis. |
