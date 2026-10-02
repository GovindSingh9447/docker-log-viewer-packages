# DockBeacon packages

Public apt / yum repository. Packages are **GPG-signed**.

Public key: [KEY.gpg](https://govindsingh9447.github.io/docker-log-viewer-packages/KEY.gpg) · Checksums: [SHA256SUMS.txt](https://govindsingh9447.github.io/docker-log-viewer-packages/SHA256SUMS.txt)

**Site:** https://govindsingh9447.github.io/docker-log-viewer-packages/

```bash
# Debian / Ubuntu — inspect, then run
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-apt.sh -o install-apt.sh
less install-apt.sh
sudo bash install-apt.sh
sudo apt-get install docker-log-viewer

# RHEL / Fedora / Rocky
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-yum.sh -o install-yum.sh
less install-yum.sh
sudo bash install-yum.sh
sudo dnf install docker-log-viewer
```
