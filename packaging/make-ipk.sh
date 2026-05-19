#!/usr/bin/env bash
IPK_DIR="$1"
RESULT="$2"

error() { echo >&2 "$@"; exit 1; }

set -e

usage()
{
    echo "Usage: $0 <ipk-dir> <ipk-path>"
    exit 0
}

(( $# == 2 )) || error 'Missing arguments: try -h for help'

cd "$IPK_DIR/CONTROL"
tar -c --owner 0 --group 0 -z -f ../control.tar.gz *
cd "$IPK_DIR"
rm -r CONTROL
tar -c --owner 0 --group 0 -J -f data.tar.xz $(ls -I control.tar.gz)
echo "2.0" > debian-binary
ar rcs "$RESULT" debian-binary control.tar.gz data.tar.xz
