#!/bin/sh
# Adds the docker-log-viewer apt repo (GPG signed-by).
# Prefer: curl -o this file, review, then sudo bash.
set -e
BASE="https://govindsingh9447.github.io/docker-log-viewer-packages"
install -d -m 0755 /usr/share/keyrings
curl -fsSL "${BASE}/KEY.gpg" -o /usr/share/keyrings/docker-log-viewer.gpg
echo "deb [signed-by=/usr/share/keyrings/docker-log-viewer.gpg] ${BASE}/apt stable main" | tee /etc/apt/sources.list.d/docker-log-viewer.list
apt-get update -o Dir::Etc::sourcelist="sources.list.d/docker-log-viewer.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
echo "Repo added. Run: apt-get install docker-log-viewer"
echo "Checksums: ${BASE}/SHA256SUMS.txt"
