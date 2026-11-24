#!/bin/sh
set -eu
cd "$(dirname "$0")"
PREFIX=${PREFIX:-$HOME/.local}
DEST="$PREFIX/opt/cursor-switcher"
mkdir -p "$DEST" "$PREFIX/share/applications" "$PREFIX/share/icons/hicolor/256x256/apps" "$PREFIX/share/metainfo"
install -m755 cursor-switcher "$DEST/"
rm -rf "$DEST/cursor-switcher.resources"
cp -r cursor-switcher.resources "$DEST/"
install -m644 helper.py icon.png "$DEST/"
mkdir -p "$PREFIX/bin"
ln -sf ../opt/cursor-switcher/cursor-switcher "$PREFIX/bin/cursor-switcher"
install -m644 cursor-switcher.desktop "$PREFIX/share/applications/"
install -m644 cursor-switcher.metainfo.xml "$PREFIX/share/metainfo/"
install -m644 icon.png "$PREFIX/share/icons/hicolor/256x256/apps/cursor-switcher.png"
update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "$PREFIX/share/icons/hicolor" 2>/dev/null || true
echo "installed to $DEST"
