# docker-log-viewer packages

Public **apt** and **dnf/yum** repository for Docker Log Viewer — a lightweight self-hosted Docker operations console (live logs, metrics, multi-host agents).

Source code is private. This repository only hosts installable packages on GitHub Pages.

**Site:** https://govindsingh9447.github.io/docker-log-viewer-packages/  
**Guide:** https://govindsingh9447.github.io/docker-log-viewer-packages/guide.html  
**Security:** https://govindsingh9447.github.io/docker-log-viewer-packages/index.html#security  
**Checksums:** https://govindsingh9447.github.io/docker-log-viewer-packages/SHA256SUMS.txt

## Install

Packages on GitHub Pages are currently **unsigned** (`trusted=yes` / `gpgcheck=0`). Inspect the install script, then run it.

```bash
# Debian / Ubuntu
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

Then:

```bash
sudo nano /etc/docker-log-viewer/docker-log-viewer.env
sudo systemctl enable --now docker-log-viewer
```

## Branches

| Branch | Contents |
|--------|----------|
| `main` | This README |
| `gh-pages` | Generated apt/yum tree + install site (updated by CI on each release) |

## Related docs

Install guide and packaging notes live in the private source repository (`docs/INSTALL.md`, `PACKAGING.md`).
