#!/usr/bin/env bash

error() { echo >&2 "$@"; exit 1; }

set -e

usage()
{
    echo "Usage: $0 <top-path> <build-path> <app-name> <version>"
    exit 0
}

(( $# == 4 )) || error 'Missing arguments: try -h for help'

# Arguments
TOP_DIR="$1"
BUILD_DIR="$2"
APP="$3"
VERSION="$4"
# Package metadata
PACKAGE="panda-fpga-${APP}"
DESCRIPTION="PandABlocks-FPGA machine-dependent package"
DEPENDS="panda-fpga-loader"
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
FPGA_DIR="opt/share/$PACKAGE"
mkdir -p "$FPGA_DIR"
cp -a "$BUILD_DIR/autogen/config_d" "$FPGA_DIR/config_d"
cp -a "$BUILD_DIR/extensions" "$BUILD_DIR/ipmi.ini" \
    "$BUILD_DIR/FPGA/panda_top.bin" "$FPGA_DIR/"
mkdir "$FPGA_DIR/template_designs"
cp "$TOP_DIR/docs/tutorials/"*.json "$FPGA_DIR/template_designs"
$TOP_DIR/packaging/opkg-utils/opkg-build -o 0 -g 0 -Z xz "$IPK_DIR" "$BUILD_DIR"
