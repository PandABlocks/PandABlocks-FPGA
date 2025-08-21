#!/usr/bin/env bash

error() { echo >&2 "$@"; exit 1; }

set -e

usage()
{
    cat <<EOF
Usage: $0 [options] <target> <version>

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

TARGET="$1"
PKG_NAME="panda-fpga-boot"
LOWER_TARGET="${TARGET,,}"
SANE_TARGET="${LOWER_TARGET//_/-}"
VERSION="${SANE_TARGET}-$2"

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
Description: PandABlocks-FPGA boot package
 PandABlocks-FPGA boot package.
Section: base
Priority: optional
License: Apache-2.0
Architecture: all
EOF
tar -czf control.tar.gz "./control" --owner=0 --group=0
echo '2.0' > debian-binary
mkdir -p boot
cp -a "$BUILD_DIR/../../targets/$TARGET/boot/"* boot
mv boot/devicetree.dtb boot/system.dtb
tar -cJf data.tar.xz ./boot --owner=0 --group=0
rm -f "$IPK"
ar -crf "$IPK" ./debian-binary ./control.tar.gz ./data.tar.xz 
