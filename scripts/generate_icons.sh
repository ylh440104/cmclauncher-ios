#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/Natives/resources/appicon-source.png}"
OUT="$ROOT/Natives/resources"

if [ ! -f "$SRC" ]; then
    echo "icon source missing: $SRC" >&2
    exit 1
fi

render() {
    size="$1"
    name="$2"
    convert "$SRC" -resize "${size}x${size}" -background white -alpha remove -alpha off \
        -define png:color-type=2 "$OUT/$name"
}

for prefix in AppIcon AppIcon-Light AppIcon-Dark AppIcon-Development; do
    render 120 "${prefix}60x60@2x.png"
    render 180 "${prefix}60x60@3x.png"
    render 152 "${prefix}76x76@2x~ipad.png"
    render 167 "${prefix}83.5x83.5@2x~ipad.png"
done

render 1024 "AppIcon-1024.png"

echo "icons regenerated in $OUT"