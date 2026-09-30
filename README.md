<div align="center">

# DockBeacon

**Docker and PM2 logs from all your servers, in one browser tab.**

Self-hosted · single binary · apt / dnf / yum · amd64 + arm64

[Website](https://dock-beacon.web.app/) · [Install](#install) · [Guide](https://dock-beacon.web.app/guide.html) · [Changelog](https://dock-beacon.web.app/#changelog) · [Report a bug](../../issues/new/choose)

![DockBeacon: live merged container logs](https://dock-beacon.web.app/demo.png)

</div>

## Why DockBeacon

`docker logs` is perfect until your third SSH tab, second host, and first "wait, which terminal was prod?" moment. DockBeacon gives your team one place to watch and act on what is running **right now**, without building an observability stack.

- **Live logs:** stream and merge many containers, regex filter, pretty JSON, time ranges, download.
- **PM2 too:** on Node hosts, switch Logs between Docker and PM2. Operators can start, stop, or restart apps.
- **Many servers, one UI:** install agents on other hosts and switch between them from the header, or group them into one merged view.
- **System status:** CPU, memory, and disk (total, used, free) for the selected server.
- **Container stats:** live CPU and memory beside the logs.
- **Compose stacks:** up, down, restart, and `.env` edits.
- **Teams:** viewer, operator, and admin roles, optional SSO (OIDC), audit log.
- **Easy to run:** a systemd service installed with apt or dnf. No container, no database, no agent sidecars.

## Install

One command. It detects apt, dnf, or yum, asks **standalone** (web UI) or **agent** (reports to a central UI), starts the service, and prints the URL and first admin password.

```bash
curl -fsSL https://dock-beacon.web.app/install.sh -o install.sh
less install.sh      # inspect first
sudo bash install.sh
```

Then open `http://<server>:9447`. For production, put it behind an HTTPS reverse proxy ([nginx example](https://dock-beacon.web.app/#production)).

<details>
<summary>Manual install with apt or dnf</summary>

```bash
# Debian / Ubuntu
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-apt.sh | sudo bash
sudo apt-get install docker-log-viewer

# RHEL / Rocky / Fedora / Amazon Linux
curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install-yum.sh | sudo bash
sudo dnf install docker-log-viewer

sudo nano /etc/docker-log-viewer/docker-log-viewer.env
sudo systemctl enable --now docker-log-viewer
```

Packages are currently unsigned (`trusted=yes` / `gpgcheck=0`); verify against [SHA256SUMS.txt](https://govindsingh9447.github.io/docker-log-viewer-packages/SHA256SUMS.txt).
</details>

## Upgrade

```bash
# apt
sudo apt-get update && sudo apt-get install -y --only-upgrade -o Dpkg::Options::=--force-confold docker-log-viewer
# dnf / yum
sudo yum update -y docker-log-viewer
```

Your settings are kept. More in [Upgrade](https://dock-beacon.web.app/#upgrade).

## Where it fits

| Tool | Best for |
|------|----------|
| `docker logs` | One container, one host |
| Dozzle | Lightweight real-time container logs |
| Portainer | Full container management |
| **DockBeacon** | **Live multi-host operations: Docker + PM2 logs, metrics, host status, Compose, roles** |
| Loki / ELK | Long-term log storage and search |

## Feedback

Found a bug or want a feature? [Open an issue](../../issues/new/choose). If DockBeacon saves you some SSH tabs, a ⭐ helps others find it.

---

This repository hosts the public apt/yum packages (`gh-pages` branch, published by CI on each release) and this README. The application source is not public.
