#!/usr/bin/env bash

error() { echo >&2 "$@"; exit 1; }

set -e

usage()
{
    cat <<EOF
Usage: $0 [options] <app-name> <version>

Options can be any of:
    -b: System build path, used for b options in list file.
    -t: Source top path, used for t options in list file.
    -d: Destination directory
        The above three options default to the current directory if not
        specified.
    -w: Workspace for building package.  Defaults to temporary directory if not
        specified.
    -h  Show this help text

EOF
    exit 0
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Argument processing.

# Path to build directory, used for b options, defaults to current directory
BUILD_DIR="$PWD"
# Top directory, used for t options, defaults to current directory
TOP_DIR="$PWD"
# Work directory for building intermedate files, will default to temporary dir
WORK_DIR=
# Destination directory for result, defaults to current directory
DEST_DIR="$PWD"
# Separator for output ipkg filename, defaults to @ character
SEP=@

while getopts 'b:t:w:d:n:ah' option; do
    case "$option" in
    b)  BUILD_DIR="$OPTARG" ;;
    t)  TOP_DIR="$OPTARG" ;;
    w)  WORK_DIR="$OPTARG" ;;
    d)  DEST_DIR="$OPTARG" ;;
    h)  usage ;;
    *)  error 'Invalid option: try -h for help' ;;
    esac
done
shift $((OPTIND-1))
(( $# == 2 )) || error 'Missing arguments: try -h for help'

APP="$1"
LOWER_APP="${APP,,}"
SANE_APP="${LOWER_APP//_/-}"
PKG_NAME="panda-fpga-${SANE_APP}"
VERSION="$2"

# If no workspace specified, use a temporary directory.
if [[ -z $WORK_DIR ]]; then
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "$WORK_DIR"' EXIT
fi

# Ensure our workspace is clean
IPK_DIR="$WORK_DIR/ipkg-$PKG_NAME"
IPK="$DEST_DIR/$PKG_NAME$SEP$VERSION.ipk"
rm -rf "$IPK_DIR"
mkdir "$IPK_DIR"
cd "$IPK_DIR"

cat <<EOF > "$IPK_DIR/control"
Package: $PKG_NAME
Version: $VERSION
Description: PandABlocks-FPGA machine-dependent package
 PandABlocks-FPGA machine-dependent package.
Section: base
Priority: optional
License: Apache-2.0
Architecture: all
Depends: panda-fpga-loader
EOF
tar -czf control.tar.gz "./control" --owner=0 --group=0
echo '2.0' > debian-binary
FPGA_DIR="opt/share/$PKG_NAME"
mkdir -p "$FPGA_DIR"
cp -a "$BUILD_DIR/autogen/config_d" "$FPGA_DIR/config_d"
cp -a "$BUILD_DIR/extensions" "$FPGA_DIR/"
cp "$BUILD_DIR/ipmi.ini" "$FPGA_DIR"
cp "$BUILD_DIR/FPGA/panda_top.bin" "$FPGA_DIR"
mkdir "$FPGA_DIR/template_designs"
cp "$TOP_DIR/docs/tutorials/"*.json "$FPGA_DIR/template_designs"
tar -cJf data.tar.xz ./opt --owner=0 --group=0
rm -f "$IPK"
ar -crf "$IPK" ./debian-binary ./control.tar.gz ./data.tar.xz
