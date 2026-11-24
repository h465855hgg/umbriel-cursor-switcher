#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
STAGE=$PWD/build-stage
TOPDIR=$PWD/build-rpm
rm -rf "$TOPDIR"
ARCH=${ARCH:-$(uname -m)}
VERSION=${VERSION:-0.1.0}
SPEC=$(mktemp)
sed "s/^Version:.*/Version:        $VERSION/" packaging/rpm/cursor-switcher.spec > "$SPEC"
rpmbuild -bb "$SPEC" \
  --define "_topdir $TOPDIR" \
  --define "stage $STAGE" \
  --define "buildarch $ARCH" \
  --define "_rpmdir $PWD/dist"
find dist -name '*.rpm' -maxdepth 3
