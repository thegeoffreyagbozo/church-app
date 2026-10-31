# ADR 0011: Sheet music as page images bundled in the app

**Status:** Accepted, amended by [ADR 0012](0012-drawn-notation-verovio.md) · **Date:** 2026-10-17 · **Amends:** [ARCHITECTURE](../ARCHITECTURE.md) (sheet music)

## Context
The choir sings from the full-music edition of the church's hymn book: a scanned book of a few
hundred pages, with all the verses printed under the notes. Choristers read staff notation and
want each hymn's music in the app's Music view, offline, on low-end Android phones. The plan
before this said one PDF per hymn, rendered offline with `pdfx`.

## Decision
- **Images, not PDFs.** Each hymn's printed music is cut from the scan into PNG pieces (black and
  white, about 240 ppi), one piece per page the hymn spans. They live in the public
  `sheet-music` bucket as `hymn_assets` rows of kind `sheet_music_image`, loaded by the importer
  from a music map (`--music`).
- **Bundled in the app.** The content build downloads the pieces of published hymns into a
  `music/` folder beside `content.db`, as `<id>.png`, and records each size so the page lays out
  before the image loads. The app shows them with no network, from the moment it is installed.
- **Drawn in the theme's ink.** A colour matrix turns black into the theme's text colour and white
  into transparency, so Paper shows dark ink on paper and Night light ink on dark. The matrix keeps
  clear pixels clear; one that made them opaque would be painted over the whole page.
- **Zoom in a full-screen view.** Tapping the music opens it full screen with pinch and
  double-tap zoom; the page itself turns off pinch-to-resize over the music.

## Alternatives
- **PDFs through `pdfx`:** bigger files, a native renderer to maintain, no per-hymn cut when two
  hymns share a page, and no way to recolour for Night.
- **Download on demand:** a smaller app, but music would need the internet once per hymn and new
  download, cache and error handling. The owner chose offline from install on 2026-10-17.
- **Drawn notation from MusicXML:** fits any screen and could do more (any verse under the notes,
  playback), but every bar of every hymn would have to be entered and checked by someone who
  reads music. It may come later for the hymns sung most.

## Consequences
- The app grows by the size of the music: about 15 to 30 MB for a whole book, measured with the
  first full build.
- New or corrected music reaches phones with the next app build, until sync exists (ADR 0002).
- A missing or broken image stops the content build; in the app, a piece that can't be shown
  says so instead of breaking the page.
