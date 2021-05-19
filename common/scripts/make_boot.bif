#!/bin/sh

# Creates bootgen interface file from arguments

cat <<EOF >"$1"
the_ROM_image: {
    [bootloader]$2
    $3
}
EOF
