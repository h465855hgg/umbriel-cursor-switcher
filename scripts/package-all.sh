#!/bin/sh
# 在当前架构上生成 rpm / deb / appimage
set -eu
cd "$(dirname "$0")/.."
ARCH=${1:-$(uname -m)}
case "$ARCH" in
  x86_64) DEB_ARCH=amd64 ;;
  aarch64|arm64) ARCH=aarch64; DEB_ARCH=arm64 ;;
  *) echo "不支持的架构: $ARCH" >&2; exit 1 ;;
esac
[ -d build-stage ] || ./scripts/stage.sh
ARCH=$ARCH ./scripts/package-rpm.sh
ARCH=$DEB_ARCH ./scripts/package-deb.sh
ARCH=$ARCH ./scripts/package-appimage.sh || echo "AppImage 跳过（工具或 GTK 打包失败）"
(cd dist && sha256sum * > SHA256SUMS.txt)
find dist -maxdepth 2 -type f | sort
