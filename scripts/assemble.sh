#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/Natives/build"
APP="$BUILD/CMCLauncher.app"
RUNTIME_SRC="${1:-}"
OUT="$ROOT/artifacts/Payload/CMCLauncher.app"

if [ ! -d "$APP" ]; then
    echo "native build missing: $APP" >&2
    exit 1
fi

rm -rf "$ROOT/artifacts"
mkdir -p "$OUT"
mkdir -p "$OUT/Frameworks" "$OUT/libs" "$OUT/Base.lproj"

cp "$APP/CMCLauncher" "$OUT/CMCLauncher"
cp "$APP/Info.plist" "$OUT/Info.plist"

cp -R "$ROOT/Natives/resources/"* "$OUT/"
cp "$BUILD/"*.dylib "$OUT/Frameworks/" 2>/dev/null || true
cp "$ROOT/Natives/resources/Frameworks/"* "$OUT/Frameworks/" 2>/dev/null || true

cp "$ROOT/JavaApp/build/launcher.jar" "$OUT/libs/"
cp "$ROOT/JavaApp/build/lwjgl.jar" "$OUT/libs/"
cp "$ROOT/JavaApp/build/patchjna_agent.jar" "$OUT/libs/"

if [ -n "$RUNTIME_SRC" ] && [ -d "$RUNTIME_SRC" ]; then
    cp -R "$RUNTIME_SRC/java_runtimes" "$OUT/"
    cp -R "$RUNTIME_SRC/libs_caciocavallo" "$OUT/"
    cp -R "$RUNTIME_SRC/libs_caciocavallo17" "$OUT/"
    for extra in arc_dns_injector.jar gson-2.10.1.jar jsr305.jar lwjgl-shaderc.jar lwjgl-vma.jar lwjgl-vulkan.jar lwjgl3-minecraft.jar; do
        if [ -f "$RUNTIME_SRC/libs/$extra" ]; then
            cp "$RUNTIME_SRC/libs/$extra" "$OUT/libs/"
        fi
    done
else
    echo "warning: no runtime payload supplied, app bundle will not boot" >&2
fi

chmod -R 755 "$OUT"
echo "$OUT"
