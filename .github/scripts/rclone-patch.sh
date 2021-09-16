#!/bin/bash
# Installation of go & temporary rclone patch applied until symlinks issue using rclone mount is resolved (see below):
# https://github.com/rclone/rclone/issues/2975

#Install go
curl -OL https://golang.org/dl/go1.17.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

#Install rclone patch
git clone https://github.com/PandABlocks/rclone.git
cd rclone
git checkout traack_symlinks
make
./rclone version
cd home/runner/go/bin/
sudo cp rclone /usr/bin/
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
sudo mkdir -p /usr/local/share/man/man1
sudo cp rclone /usr/local/share/man/man1/
sudo mandb
rclone version
