# docker-log-viewer packages

Public **apt** and **dnf/yum** repository for [docker-log-viewer](https://github.com/GovindSingh9447/docker-log-viewer).

Source code is private. This repository only hosts installable packages on GitHub Pages.

## Install

**Site:** https://govindsingh9447.github.io/docker-log-viewer-packages/

```bash
# Debian / Ubuntu
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-apt.sh | sudo bash
sudo apt-get install docker-log-viewer

# RHEL / Fedora / Rocky
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-yum.sh | sudo bash
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
