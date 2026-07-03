#!/usr/bin/env bash
# Install nvc VHDL simulator from pre-built GitHub release .deb packages.
# nvc is not in the Ubuntu apt repos, so we fetch the binary from the project's
# GitHub releases. Packages are provided for Ubuntu 22.04, 24.04, and 26.04.
set -euo pipefail

NVC_VERSION="1.21.1"

# Read the Ubuntu version from /etc/os-release
. /etc/os-release
UBUNTU_VERSION="${VERSION_ID}"

DEB_URL="https://github.com/nickg/nvc/releases/download/r${NVC_VERSION}/nvc_${NVC_VERSION}-1_amd64_ubuntu-${UBUNTU_VERSION}.deb"
DEB_FILE="/tmp/nvc_${NVC_VERSION}.deb"

curl -fsSL "${DEB_URL}" -o "${DEB_FILE}"
apt-get install -y "${DEB_FILE}"
rm -f "${DEB_FILE}"
