#!/bin/bash
# Grants access to the s3 bucket containing vivado

# S3_ACCESS_KEY_ID=$1
# S3_SECRET_ACCESS_KEY=$2

sudo mkdir -p /tools/Xilinx
mkdir -p /home/runner/.config/rclone
cd /home/runner/.config/rclone/
touch rclone.conf

cat >> rclone.conf <<EOL
[fpga-vivado]
type = s3
provider = Ceph
env_auth = true
# access_key_id = $S3_ACCESS_KEY_ID
# secret_access_key = $S3_SECRET_ACCESS_KEY
region =
endpoint = https://s3.echo.stfc.ac.uk
EOL

sudo rclone mount --file-perms 0777 --attr-timeout=10m --no-modtime --read-only --daemon fpga-vivado:dls-controls-fpga-vivado /tools/Xilinx
sudo -s source /tools/Xilinx/Vivado/2020.2/settings64.sh
vivado
fusermount -u /tools/Xilinx
