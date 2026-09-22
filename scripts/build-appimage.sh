#!/usr/bin/env bash
# Package a built Flutter Linux bundle as an AppImage.
# The bundle (binary + lib/ + data/) lands under AppDir/usr/bin with a
# desktop entry and icon at the AppDir root.
#
# Usage: scripts/build-appimage.sh <bundle-dir> <arch> <output-file>
#   arch: x86_64 or aarch64
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-appimage.sh <bundle-dir> <arch> <output-file>}"
ARCH="${2:?usage: build-appimage.sh <bundle-dir> <arch> <output-file>}"
OUT="${3:?usage: build-appimage.sh <bundle-dir> <arch> <output-file>}"
ICON="${4:-android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png}"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "build-appimage: bundle dir not found: $BUNDLE_DIR" >&2
  exit 1
fi
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
  echo "build-appimage: unsupported arch: $ARCH" >&2
  exit 1
fi

APPDIR="$(mktemp -d)/Glam.AppDir"
trap 'rm -rf "$(dirname "$APPDIR")"' EXIT
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE_DIR/." "$APPDIR/usr/bin/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/glam" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/glam.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Glam
Comment=GitLab client for desktop and mobile
Exec=glam
Icon=glam
Categories=Development;
Terminal=false
EOF

install -m 644 "$ICON" "$APPDIR/glam.png"

TOOL="$(mktemp -d)/appimagetool"
curl -fsSL --retry 3 -o "$TOOL" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
chmod +x "$TOOL"

# --appimage-extract-and-run avoids needing FUSE inside CI containers.
ARCH="$ARCH" "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT"
echo "build-appimage: $OUT"
