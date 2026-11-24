#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
VERSION=${VERSION:-0.1.0}
ARCH=${ARCH:-$(uname -m)}
case "$ARCH" in aarch64|arm64) ARCH=aarch64 ;; esac
TOOLS=$PWD/tools
mkdir -p "$TOOLS"
fetch() {
  [ -x "$TOOLS/$2" ] && return 0
  curl -fsSL "$1" -o "$TOOLS/$2" && chmod +x "$TOOLS/$2"
}
fetch "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage" "linuxdeploy-${ARCH}.AppImage"
fetch "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage" "appimagetool-${ARCH}.AppImage"
fetch "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh" "linuxdeploy-plugin-gtk.sh"
fetch "https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-${ARCH}" "runtime-${ARCH}"
APPDIR=$PWD/AppDir
BIN=$PWD/build-stage/opt/cursor-switcher
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps" "$APPDIR/usr/share/metainfo"
cp -a "$BIN/cursor-switcher" "$BIN/cursor-switcher.resources" "$BIN/helper.py" "$BIN/icon.png" "$APPDIR/usr/bin/"
cp cursor-switcher.desktop "$APPDIR/usr/share/applications/"
cp cursor-switcher.metainfo.xml "$APPDIR/usr/share/metainfo/"
cp icon.png "$APPDIR/cursor-switcher.png"
cp icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/cursor-switcher.png"
if [ -d build-stage/usr/share/icons/PRTS-Final ]; then
  cp -a build-stage/usr/share/icons/PRTS-Final build-stage/usr/share/icons/PRTS-Final-Static "$APPDIR/usr/share/icons/"
fi
cat > "$APPDIR/AppRun" <<'RUN'
#!/bin/sh
exec "$APPDIR/usr/bin/cursor-switcher" "$@"
RUN
chmod +x "$APPDIR/AppRun"
export PATH="$TOOLS:$PATH"
export ARCH
"$TOOLS/linuxdeploy-${ARCH}.AppImage" --appimage-extract-and-run \
  --appdir "$APPDIR" \
  --executable "$APPDIR/usr/bin/cursor-switcher" \
  --desktop-file "$APPDIR/usr/share/applications/cursor-switcher.desktop" \
  --icon-file icon.png \
  --plugin gtk
mkdir -p dist
rm -f "dist/cursor-switcher-${VERSION}-${ARCH}.AppImage"
TOOL="$TOOLS/appimagetool-${ARCH}.AppImage"
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a "$TOOL" --appimage-extract-and-run --runtime-file "$TOOLS/runtime-${ARCH}" "$APPDIR" "dist/cursor-switcher-${VERSION}-${ARCH}.AppImage"
else
  "$TOOL" --appimage-extract-and-run --runtime-file "$TOOLS/runtime-${ARCH}" "$APPDIR" "dist/cursor-switcher-${VERSION}-${ARCH}.AppImage"
fi
ls -lh "dist/cursor-switcher-${VERSION}-${ARCH}.AppImage"
