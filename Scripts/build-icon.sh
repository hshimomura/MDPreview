#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
SOURCE_ICON="$PROJECT_ROOT/Resources/AppIcon-1024.png"
ICONSET_DIR="$PROJECT_ROOT/.build/AppIcon.iconset"
OUTPUT_ICON="$PROJECT_ROOT/Resources/AppIcon.icns"
ASSET_ICONSET_DIR="$PROJECT_ROOT/Resources/AppIcon.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE_ICON" ]]; then
    print -u2 "Missing icon master: $SOURCE_ICON"
    exit 1
fi

mkdir -p "$ICONSET_DIR" "$ASSET_ICONSET_DIR"

typeset -a icon_variants
icon_variants=(
    "16 icon_16x16.png"
    "32 icon_16x16@2x.png"
    "32 icon_32x32.png"
    "64 icon_32x32@2x.png"
    "128 icon_128x128.png"
    "256 icon_128x128@2x.png"
    "256 icon_256x256.png"
    "512 icon_256x256@2x.png"
    "512 icon_512x512.png"
    "1024 icon_512x512@2x.png"
)

for variant in "${icon_variants[@]}"; do
    size="${variant%% *}"
    filename="${variant#* }"
    /usr/bin/sips \
        -z "$size" "$size" \
        "$SOURCE_ICON" \
        --out "$ICONSET_DIR/$filename" \
        >/dev/null
    /usr/bin/ditto \
        "$ICONSET_DIR/$filename" \
        "$ASSET_ICONSET_DIR/$filename"
done

/usr/bin/iconutil \
    -c icns \
    "$ICONSET_DIR" \
    -o "$OUTPUT_ICON"

print "Built $OUTPUT_ICON"
