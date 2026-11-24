#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
STAGE=$PWD/build-stage
TOPDIR=$PWD/build-rpm
rm -rf "$TOPDIR"
ARCH=${ARCH:-$(uname -m)}
rpmbuild -bb packaging/rpm/cursor-switcher.spec \
  --define "_topdir $TOPDIR" \
  --define "stage $STAGE" \
  --define "buildarch $ARCH" \
  --define "_rpmdir $PWD/dist"
find dist -name '*.rpm' -maxdepth 3
