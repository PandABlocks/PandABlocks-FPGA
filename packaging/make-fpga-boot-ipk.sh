#!/usr/bin/env bash

error() { echo >&2 "$@"; exit 1; }

set -e

usage()
{
    echo "Usage: $0 <top-path> <build-path> <target> <version>"
    exit 0
}

(( $# == 4 )) || error 'Missing arguments: try -h for help'

# Arguments
TOP_DIR="$1"
BUILD_DIR="$2"
TARGET="$3"
VERSION="${TARGET}-$4"
# Package metadata
PACKAGE="panda-fpga-boot"
DESCRIPTION="PandABlocks-FPGA boot files for $TARGET"
DEPENDS=""
# Temporary work directory to build the package
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
IPK_DIR="$WORK_DIR/ipk-$PACKAGE"
mkdir -p "$IPK_DIR/CONTROL"
cd "$IPK_DIR"
sed -e "s|@PACKAGE@|$PACKAGE|" \
    -e "s|@VERSION@|$VERSION|" \
    -e "s|@DESCRIPTION@|$DESCRIPTION|" \
    -e "s|@DEPENDS@|$DEPENDS|" \
    $TOP_DIR/packaging/ipk-control-template > $IPK_DIR/CONTROL/control
mkdir boot
cp -a "$BUILD_DIR/../../targets/$TARGET/boot/"* boot/
mv boot/devicetree.dtb boot/system.dtb
$TOP_DIR/packaging/opkg-utils/opkg-build -o 0 -g 0 -Z xz "$IPK_DIR" "$BUILD_DIR"
