#!/bin/sh
# 把构建产物整理成统一的安装树：build-stage/
set -eu
cd "$(dirname "$0")/.."
BIN=$(find .huxerui/build -type f -name cursor_switcher -perm -u+x -path '*release*' | head -1)
[ -n "$BIN" ] || { echo "找不到构建产物，先跑 huxerui build linux --config release" >&2; exit 1; }
RES="$(dirname "$BIN")/cursor_switcher.resources"
rm -rf build-stage
mkdir -p build-stage/opt/cursor-switcher build-stage/usr/bin build-stage/usr/share/applications build-stage/usr/share/icons/hicolor/256x256/apps build-stage/usr/share/metainfo
cp "$BIN" build-stage/opt/cursor-switcher/cursor-switcher
cp -r "$RES" build-stage/opt/cursor-switcher/cursor-switcher.resources
cp helper.py icon.png build-stage/opt/cursor-switcher/
ln -sf ../opt/cursor-switcher/cursor-switcher build-stage/usr/bin/cursor-switcher
sed 's#^Exec=.*#Exec=cursor-switcher#; s#^Icon=.*#Icon=cursor-switcher#' cursor-switcher.desktop > build-stage/usr/share/applications/cursor-switcher.desktop
cp icon.png build-stage/usr/share/icons/hicolor/256x256/apps/cursor-switcher.png
cp cursor-switcher.metainfo.xml build-stage/usr/share/metainfo/
THEME_SRC=${THEME_SRC:-$PWD/../assets/PRTS-Linux-1.1.5/PRTS-Linux/files}
if [ -d "$THEME_SRC" ]; then
  mkdir -p build-stage/usr/share/icons
  cp -a "$THEME_SRC/PRTS-Final" "$THEME_SRC/PRTS-Final-Static" build-stage/usr/share/icons/
  echo "themes: PRTS-Final + PRTS-Final-Static"
else
  echo "警告: 主题源不存在（THEME_SRC=$THEME_SRC），包内不含主题" >&2
fi
echo "staged: $(du -sh build-stage | cut -f1)"
