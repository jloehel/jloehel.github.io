#!/bin/sh
#
# Vendors self-hosted fonts (Adobe) and Font Awesome Free SVG icons so the live
# site needs no third-party CDN. Fonts are latin-subset and renamed (OFL Reserved
# Font Name). Run, review the diff, commit assets/ + _includes/icons/.
#
# Usage: update-assets.sh [all|fonts|icons]   (default: all)
set -eu

PINS="$(dirname "$0")/../_data/versions.yml"

pin() {  # key -> value
  value="$(sed -n "s/^$1: *\"\([^\"]*\)\".*/\1/p" "$PINS")"
  [ -n "$value" ] || { echo "ERROR: '$1' fehlt in $PINS" >&2; exit 1; }
  echo "$value"
}

FA_VER="$(pin font_awesome)"
SANS_TAG="$(pin source_sans)"
SCP_TAG="$(pin source_code_pro)"

# tag 2.042R-u/1.062R-i/1.026R-vf -> archive 2.042R-u_1.062R-i_1.026Rvf
SCP_FILE="$(printf '%s' "$SCP_TAG" | tr '/' '_' | sed 's/-vf$/vf/')"

SANS_URL="https://github.com/adobe-fonts/source-sans/releases/download/${SANS_TAG}/WOFF2-source-sans-${SANS_TAG}.zip"
SCP_URL="https://github.com/adobe-fonts/source-code-pro/releases/download/${SCP_TAG}/WOFF2-source-code-pro-${SCP_FILE}.zip"
FA_URL="https://github.com/FortAwesome/Font-Awesome/releases/download/${FA_VER}/fontawesome-free-${FA_VER}-web.zip"

# "fontWeight:cssWeight" pairs
SANS_WEIGHTS="Regular:400 Semibold:600 Bold:700"
SCP_WEIGHTS="Regular:400 Semibold:600"

# "name:style" pairs
FA_ICONS="
linkedin:brands xing:brands github:brands gitlab:brands keybase:brands
bars:solid xmark:solid moon:solid sun:solid heart:solid envelope:solid rss:solid
"

# Latin subset for en/de/es: one range per line, add/remove freely.
add_unicode() { UNICODES="${UNICODES:+$UNICODES,}$1"; }
UNICODES=""
add_unicode U+0000-00FF   # Basic Latin + Latin-1 (ä ö ü ß ñ á é í ó ú …)
add_unicode U+0131        # ı dotless i
add_unicode U+0152-0153   # Œ œ
add_unicode U+02BB-02BC   # ʻ ʼ modifier apostrophes
add_unicode U+02C6        # ˆ circumflex
add_unicode U+02DA        # ˚ ring above
add_unicode U+02DC        # ˜ small tilde
add_unicode U+2000-206F   # general punctuation (– — “ ” ‘ ’ … )
add_unicode U+2074        # ⁴ superscript four
add_unicode U+20AC        # € euro
add_unicode U+2122        # ™ trademark
add_unicode U+2191        # ↑ up arrow
add_unicode U+2193        # ↓ down arrow
add_unicode U+2212        # − minus
add_unicode U+2215        # ∕ division slash
add_unicode U+FEFF        # zero-width no-break space / BOM
add_unicode U+FFFD        # � replacement character

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FONT_DIR="$ROOT/assets/fonts"
ICON_DIR="$ROOT/_includes/icons"
TMP="$(mktemp -d)"

require() {
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: '$tool' not in PATH" >&2; exit 1; }
  done
}

fetch() {  # url -> path
  out="$TMP/$(basename "$1")"
  curl -fsSL "$1" -o "$out"
  echo "$out"
}

subset() {  # extracted_dir fontWeight out-name renameKey
  if [ "$2" = "Bold" ]; then
    src="$(find "$1" -type f -iname '*Bold*.woff2' ! -iname '*Semibold*' ! -iname '*It.*' | sort | head -1)"
  else
    src="$(find "$1" -type f -iname "*$2*.woff2" ! -iname '*It.*' | sort | head -1)"
  fi
  [ -n "$src" ] || { echo "ERROR: no $2 woff2 in archive" >&2; exit 1; }
  echo "    $(basename "$src") -> $3"
  pyftsubset "$src" --output-file="$FONT_DIR/$3" --flavor=woff2 \
    --unicodes="$UNICODES" --name-IDs='*' --layout-features="kern,liga,calt,ccmp,locl,mark,mkmk,frac"
  python3 "$ROOT/bin/rename-font.py" "$FONT_DIR/$3" "$4"
}

vendor_fonts() {  # label url dir prefix renameKey "weights"
  echo "$1"
  unzip -qo "$(fetch "$2")" -d "$3"
  for pair in $6; do
    subset "$3" "${pair%%:*}" "$4-${pair##*:}.woff2" "$5"
  done
}

vendor_icons() {
  echo "Font Awesome Free ($FA_VER)"
  unzip -qo "$(fetch "$FA_URL")" -d "$TMP/fa"
  count=0
  for entry in $FA_ICONS; do
    name="${entry%%:*}"
    style="${entry##*:}"
    src="$(find "$TMP/fa" -path "*/svgs/$style/$name.svg" | head -1)"
    [ -n "$src" ] || { echo "ERROR: FA $style/$name.svg not found" >&2; exit 1; }
    cp "$src" "$ICON_DIR/$name.svg"
    count=$((count + 1))
  done
  echo "    $count icons -> _includes/icons/"
}

run_fonts() {
  require curl unzip pyftsubset python3
  mkdir -p "$FONT_DIR"
  vendor_fonts "Source Sans 3 ($SANS_TAG)"   "$SANS_URL" "$TMP/sans" source-sans-3   sans "$SANS_WEIGHTS"
  vendor_fonts "Source Code Pro ($SCP_TAG)"  "$SCP_URL"  "$TMP/scp"  source-code-pro mono "$SCP_WEIGHTS"
}

run_icons() {
  require curl unzip
  mkdir -p "$ICON_DIR"
  vendor_icons
}

case "${1:-all}" in
  all)   run_fonts; run_icons ;;
  fonts) run_fonts ;;
  icons) run_icons ;;
  *)     echo "usage: $0 [all|fonts|icons]" >&2; exit 1 ;;
esac
echo "Temp archives: $TMP"
