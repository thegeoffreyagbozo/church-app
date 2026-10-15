# churches/

One folder per church (ADR 0007). Only `example/` is committed: real churches' folders stay on
the build machine, with a private backup.

- `church.json`: the church's public identity and branding, passed to builds with
  `--dart-define-from-file`.
- `prod.json`: that church's backend (added with per-church builds, piece 3).

| Key | Meaning |
|---|---|
| `APP_NAME` | Home-screen label (used from piece 3) |
| `APP_ID` | Package ID: the church's domain reversed (used from piece 3) |
| `BRAND_PRIMARY` | Numbers, buttons and the reading band, as `#RRGGBB` |
| `BRAND_ACCENT` | Kickers and verse numbers, as `#RRGGBB` |
| `CHURCH_TAGLINE` | Optional line under the church name on Home; leave empty for none |

The app adjusts both colours until all text on Paper and Night meets WCAG AA, so any brand
colours work. Without a settings file the app uses neutral ink blue and oxblood.
