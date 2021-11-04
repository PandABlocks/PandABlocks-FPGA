#!/bin/sh

# Creates bootgen interface file from arguments

cat <<EOF >"$1"
the_ROM_image: {
    [bootloader,destination_cpu=a53-0] $2
    [pmufw_image] $3
    [destination_cpu=a53-0,exception_level=el-3,trustzone] $4
    [destination_cpu=a53-0,exception_level=el-2] $5
}
EOF
