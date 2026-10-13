#!/usr/bin/env bash
# Downloads the app's fonts (static TrueType files from Google Fonts) and their licences
# into assets/fonts. All four families are under the SIL Open Font License 1.1.
# Run from apps/mobile: bash tool/fetch_fonts.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts/licenses

# family|css axis spec|weight:style:file ...
fonts=(
  "Literata|ital,wght@0,400;0,600;0,700;1,400|400:normal:Literata-Regular 600:normal:Literata-SemiBold 700:normal:Literata-Bold 400:italic:Literata-Italic"
  "Fraunces|wght@400;600|400:normal:Fraunces-Regular 600:normal:Fraunces-SemiBold"
  "Inter|wght@400;600|400:normal:Inter-Regular 600:normal:Inter-SemiBold"
  "Atkinson Hyperlegible|ital,wght@0,400;0,700;1,400|400:normal:AtkinsonHyperlegible-Regular 700:normal:AtkinsonHyperlegible-Bold 400:italic:AtkinsonHyperlegible-Italic"
)

for entry in "${fonts[@]}"; do
  IFS='|' read -r family axes files <<<"$entry"
  # An old user agent makes the CSS API answer with TrueType (not WOFF2) URLs.
  css=$(curl -fsS -A "Mozilla/4.0" \
    "https://fonts.googleapis.com/css2?family=${family// /+}:${axes}")
  for spec in $files; do
    IFS=':' read -r weight style name <<<"$spec"
    url=$(awk -v w="$weight" -v s="$style" '
      /font-style:/ { st = $2; sub(";", "", st) }
      /font-weight:/ { wt = $2; sub(";", "", wt) }
      /src: url\(/ { if (st == s && wt == w) { match($0, /https:[^)]*/); print substr($0, RSTART, RLENGTH) } }
    ' <<<"$css")
    curl -fsS "$url" -o "assets/fonts/${name}.ttf"
    echo "assets/fonts/${name}.ttf"
  done
done

for licence in literata fraunces inter atkinsonhyperlegible; do
  curl -fsS "https://raw.githubusercontent.com/google/fonts/main/ofl/${licence}/OFL.txt" \
    -o "assets/fonts/licenses/${licence}.txt"
done
echo "assets/fonts/licenses/ (4 files)"
