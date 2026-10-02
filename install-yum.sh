#!/bin/sh
# Adds the docker-log-viewer yum repo (gpgcheck=1).
# Prefer: curl -o this file, review, then sudo bash.
set -e
BASE="https://govindsingh9447.github.io/docker-log-viewer-packages"
cat >/etc/yum.repos.d/docker-log-viewer.repo <<REPO
[docker-log-viewer]
name=DockBeacon
baseurl=${BASE}/yum
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=${BASE}/KEY.gpg
REPO
echo "Repo added. Run: dnf install docker-log-viewer"
echo "Checksums: ${BASE}/SHA256SUMS.txt"
