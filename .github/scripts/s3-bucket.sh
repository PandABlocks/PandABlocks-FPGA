#!/bin/bash
# Grants access to the s3 bucket containing vivado

# Store the password locally
echo ${{ secrets.VIVADO_S3_PASSWD }} > ${HOME}/.passwd-s3fs
chmod 600 ${HOME}/.passwd-s3fs

#Run s3fs with the vivado bucket
mkdir $(GITHUB_WORKSPACE)/vivado
s3fs dls-controls-fpga-vivado $(GITHUB_WORKSPACE)/vivado -o passwd_file=${HOME}/.passwd-s3fs

# s3fs command with debug output
# s3fs mybucket /path/to/mountpoint -o passwd_file=${HOME}/.passwd-s3fs -o dbglevel=info -f -o curldbg
