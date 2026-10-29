#!/usr/bin/env bash
# Rebuilds assets/verovio-6.3.0.zip: the music fonts Verovio needs (Bravura and Leipzig,
# which it always loads, and Leland, which the app draws with) and its text metrics, from
# the pinned release. Fonts: SIL Open Font License 1.1. Run from packages/notation:
#   bash tool/fetch_verovio_data.sh
set -euo pipefail
cd "$(dirname "$0")/.."
version=6.3.0
sha=095a561e9bd26c97787ad49e01009576d1ca234feae3995948c5aede97a40598
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
curl -fsSL "https://github.com/rism-digital/verovio/archive/refs/tags/version-$version.tar.gz" \
  -o "$work/verovio.tgz"
echo "$sha  $work/verovio.tgz" | sha256sum -c -
tar xzf "$work/verovio.tgz" -C "$work"
mkdir -p assets
rm -f "assets/verovio-$version.zip"
(cd "$work/verovio-version-$version/data" && \
  zip -qr -X "$OLDPWD/assets/verovio-$version.zip" \
    Bravura Bravura.xml Leipzig Leipzig.xml Leland Leland.xml text)
ls -la "assets/verovio-$version.zip"
