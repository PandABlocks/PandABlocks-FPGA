#!/bin/bash
# Grants access to the s3 bucket containing vivado

mkdir -p /home/runner/.config/rclone
cd /home/runner/.config/rclone/
touch rclone.conf

cat >> rclone.conf <<EOL
[fpga-vivado]
type = s3
provider = Ceph
env_auth = false
access_key_id = ${{ secrets.VIVADO_S3_ACCESS_KEY_ID }}
secret_access_key = ${{ secrets.VIVADO_S3_SECRET_ACCESS_KEYD }}
region =
endpoint = https://s3.echo.stfc.ac.uk
EOL

sudo mkdir -p /tools/Xilinx
rclone mount --file-perms 0777 --attr-timeout=10m --no-modtime --read-only --daemon fpga-vivado:dls-controls-fpga-vivado /tools/Xilinx
source /tools/Xilinx/Vivado/2020.2/settings64.sh
vivado
fusermount -u /tools/Xilinx
