#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
ARCH=${ARCH:-amd64}
VERSION=${VERSION:-0.1.0}
PKG=$PWD/build-deb
rm -rf "$PKG"
cp -a build-stage "$PKG"
mkdir -p "$PKG/DEBIAN"
cat > "$PKG/DEBIAN/control" <<CTRL
Package: cursor-switcher
Version: ${VERSION}-1
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, python3, hicolor-icon-theme
Maintainer: h465855hgg <h465855hgg@users.noreply.github.com>
Homepage: https://github.com/h465855hgg/cursor-switcher
Description: PRTS cursor theme and shader effect switcher for Umbriel
 Switch the Xcursor theme, cursor size and Umbriel cursor shader effects.
 Built with HuxerUI; changes are applied immediately.
CTRL
cat > "$PKG/DEBIAN/postinst" <<'POST'
#!/bin/sh
set -e
update-desktop-database -q >/dev/null 2>&1 || true
gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
exit 0
POST
cat > "$PKG/DEBIAN/postrm" <<'POST'
#!/bin/sh
set -e
update-desktop-database -q >/dev/null 2>&1 || true
gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
exit 0
POST
chmod 755 "$PKG/DEBIAN/postinst" "$PKG/DEBIAN/postrm"
(cd "$PKG" && find . -type f -not -path './DEBIAN/*' -printf '%P\0' | xargs -0 md5sum > DEBIAN/md5sums)
printf '2.0\n' > "$PKG/debian-binary"
tar -C "$PKG" -czf "$PKG/control.tar.gz" ./DEBIAN
tar -C "$PKG" --owner=0 --group=0 --zstd -cf "$PKG/data.tar.zst" ./opt ./usr
mkdir -p dist
OUT="dist/cursor-switcher_${VERSION}-1_${ARCH}.deb"
rm -f "$OUT"
(cd "$PKG" && ar rcs "../$OUT" debian-binary control.tar.gz data.tar.zst)
echo "$OUT"
ar t "$OUT"
