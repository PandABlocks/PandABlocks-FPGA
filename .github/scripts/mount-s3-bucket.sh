#!/bin/bash
# Grants access to the s3 bucket containing vivado

 S3_ACCESS_KEY_ID=$1
 S3_SECRET_ACCESS_KEY=$2

sudo mkdir -p /scratch/Xilinx
sudo chmod a+w /scratch
mkdir -p ~/.config/rclone

cat >> ~/.config/rclone/rclone.conf <<EOL
[fpga-vivado]
type = s3
provider = Ceph
env_auth = false
access_key_id = $S3_ACCESS_KEY_ID
secret_access_key = $S3_SECRET_ACCESS_KEY
region =
endpoint = https://s3.echo.stfc.ac.uk
EOL

chmod 600 ~/.config/rclone/rclone.conf
rclone mount --file-perms 0777 --attr-timeout=10m --no-modtime --read-only --daemon --allow-other --vfs-cache-mode full fpga-vivado:dls-controls-fpga-xilinx /scratch/Xilinx
