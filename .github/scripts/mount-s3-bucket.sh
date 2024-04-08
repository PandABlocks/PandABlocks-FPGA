#!/bin/bash
# Grants access to the s3 bucket containing vivado

 S3_ACCESS_KEY_ID=$1
 S3_SECRET_ACCESS_KEY=$2

chmod a+w /scratch
mkdir -p $HOME/.config/rclone

cat >> $HOME/.config/rclone/rclone.conf <<EOL
[fpga-vivado]
type = s3
provider = Ceph
env_auth = false
access_key_id = $S3_ACCESS_KEY_ID
secret_access_key = $S3_SECRET_ACCESS_KEY
region =
endpoint = https://s3.echo.stfc.ac.uk
EOL

chmod 600 $HOME/.config/rclone/rclone.conf
rclone copy fpga-vivado:dls-controls-fpga-xilinx/Vivado/2022.2/settings64.sh /scratch/Xilinx

# Flag to make it run the background
#  --daemon

#  ACTIONS WHEN USING S3FS:
#  sudo mkdir -p /scratch/Xilinx
#  sudo chmod -R a+rw /scratch
#  sudo ls -l /scratch
#  echo ${{ secrets.VIVADO_S3_ACCESS_KEY_ID }}:${{ secrets.VIVADO_S3_SECRET_ACCESS_KEY }} > ~/.passwd-s3fs
#  chmod 600 ~/.passwd-s3fs
#  s3fs dls-controls-fpga-vivado /scratch/Xilinx -o passwd_file=${HOME}/.passwd-s3fs -o url=https://s3.echo.stfc.ac.uk -o use_path_request_style -o ro
