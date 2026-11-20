#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/artifacts/Payload/CMCLauncher.app"
ENT="${1:-$ROOT/entitlements.trollstore.xml}"
LDID="${LDID:-ldid}"

if [ ! -d "$APP" ]; then
    echo "app bundle missing: $APP" >&2
    exit 1
fi

"$LDID" -S"$ENT" "$APP/CMCLauncher"

count=0
find "$APP" -type f | while read -r f; do
    case "$f" in
        "$APP/CMCLauncher") continue ;;
    esac
    kind=$(file -b "$f" 2>/dev/null | head -1)
    case "$kind" in
        *Mach-O*)
            "$LDID" -S "$f" >/dev/null 2>&1 || true
            ;;
    esac
done

echo "signed $APP"
echo "$APP" > "$ROOT/artifacts/.signed"