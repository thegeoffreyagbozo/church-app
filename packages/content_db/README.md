# content_db

The hymn book as an on-phone SQLite database (ADR 0001, ADR 0009): the drift schema, the
read queries and offline search the app uses, and the tool that builds the database the app
bundles.

## Build the bundled hymn book

From the repo root, after generating the drift code once:

```bash
(cd packages/content_db && dart run build_runner build --delete-conflicting-outputs)

# From a church's Supabase project (public API, publishable key: ADR 0006):
dart run content_db:build_content_db --config config/dev.json \
  --out apps/mobile/assets/content/content.db

# Or from the public-domain sample, with no Supabase at all:
dart run content_db:build_content_db \
  --from-json packages/content_db/test/fixtures/sample_content.json \
  --out apps/mobile/assets/content/content.db
```

- It reads only what anyone may read: published, non-deleted rows (row level security
  decides). Hymns whose section is hidden are left out, and the summary says how many.
- It writes `content.db` and a small `content.json` beside it; the app compares the build
  date in `content.json` with the copy on the phone to spot a newer bundle.
- `--save-json <file>` also saves what was downloaded, in the fixture's format.
- Sheet music (ADR 0011): each published hymn's music pieces (`hymn_assets` rows of kind
  `sheet_music_image`) are downloaded from the public bucket into a `music/` folder beside
  `content.db`, as `<id>.png`, and their sizes go in the database. A missing or broken file
  stops the build. For `--from-json` builds, `--music-from <dir>` gives a folder laid out like
  the bucket; without it the music is left out and the app shows the words instead.
- The output is church content: it stays out of git (`apps/mobile/assets/content/` is
  ignored).

## Tests

```bash
cd packages/content_db
dart test                       # everything except the Supabase check
SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_KEY=<local anon key> \
  dart test test/supabase_build_test.dart   # needs a local stack with the sample book
```
