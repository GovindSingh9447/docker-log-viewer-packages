#!/usr/bin/env bash
# DockBeacon one-step installer: adds the package repo, installs (or upgrades)
# docker-log-viewer, asks standalone vs agent, writes the env file, starts the
# service, and checks it answers.
#
#   curl -fsSL https://govindsingh9447.github.io/docker-log-viewer-packages/install.sh -o install.sh
#   sudo bash install.sh
#
# Unattended: set DLV_YES=1 plus any of
#   DLV_MODE=standalone|agent  DLV_SERVER_NAME  DLV_PORT  DLV_LISTEN_ADDR
#   DLV_BASE_PATH  DLV_CONTROL_URL (agent)  DLV_AUTH_SECRET (agent)
#
# Test servers: DLV_CHANNEL=testing installs and upgrades to pre-release test
# builds (vX.Y.Z-rc.N). DLV_CHANNEL=stable switches a host back to releases.
set -euo pipefail

CHANNEL="${DLV_CHANNEL:-stable}"
case "$CHANNEL" in
	stable) BASE_URL="${DLV_REPO_URL:-https://govindsingh9447.github.io/docker-log-viewer-packages}" ;;
	testing) BASE_URL="${DLV_REPO_URL:-https://govindsingh9447.github.io/docker-log-viewer-packages/testing}" ;;
	*) printf 'error: DLV_CHANNEL must be stable or testing\n' >&2; exit 1 ;;
esac
PKG=docker-log-viewer
SERVICE=docker-log-viewer
ENV_FILE=/etc/docker-log-viewer/docker-log-viewer.env
DATA_DIR=/var/lib/docker-log-viewer
GRANT=/usr/lib/docker-log-viewer/pm2-grant-access
YES="${DLV_YES:-0}"

if [ -t 1 ]; then
	B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
else
	B=; G=; Y=; R=; N=
fi
info() { printf '%s==>%s %s\n' "$G" "$N" "$*"; }
warn() { printf '%swarning:%s %s\n' "$Y" "$N" "$*" >&2; }
die() { printf '%serror:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

# Prompts read from the terminal so `curl ... | sudo bash` still works.
TTY=/dev/tty
if [ "$YES" != "1" ] && ! { : <"$TTY"; } 2>/dev/null; then
	die "no terminal for prompts. Re-run with DLV_YES=1 and DLV_* variables."
fi

ask() { # ask VAR "Question" default
	local __var=$1 __q=$2 __def=${3-} __ans
	if [ "$YES" = "1" ]; then
		printf -v "$__var" '%s' "$__def"
		return
	fi
	if [ -n "$__def" ]; then
		read -r -p "$__q [$__def]: " __ans <"$TTY" || true
	else
		read -r -p "$__q: " __ans <"$TTY" || true
	fi
	printf -v "$__var" '%s' "${__ans:-$__def}"
}

ask_secret() { # ask_secret VAR "Question"
	local __var=$1 __q=$2 __ans
	if [ "$YES" = "1" ]; then
		printf -v "$__var" '%s' ""
		return
	fi
	read -r -s -p "$__q: " __ans <"$TTY" || true
	echo >"$TTY"
	printf -v "$__var" '%s' "$__ans"
}

confirm() { # confirm "Question" default(y|n)
	local q=$1 def=${2:-y} ans
	if [ "$YES" = "1" ]; then [ "$def" = "y" ]; return; fi
	read -r -p "$q [$( [ "$def" = y ] && echo Y/n || echo y/N )]: " ans <"$TTY" || true
	ans=${ans:-$def}
	case "$ans" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# set_env KEY VALUE: replace "KEY=" or "# KEY=" in the env file, else append.
set_env() {
	local key=$1 val=$2 tmp
	tmp=$(mktemp)
	awk -v k="$key" -v v="$val" '
		!done && ($0 ~ "^[[:space:]]*" k "=" || $0 ~ "^#[[:space:]]*" k "=") { print k "=" v; done=1; next }
		{ print }
		END { if (!done) print k "=" v }
	' "$ENV_FILE" >"$tmp"
	cat "$tmp" >"$ENV_FILE"
	rm -f "$tmp"
}

unset_env() { # comment out KEY= so the default applies
	local key=$1 tmp
	tmp=$(mktemp)
	awk -v k="$key" '$0 ~ "^[[:space:]]*" k "=" { print "# " $0; next } { print }' "$ENV_FILE" >"$tmp"
	cat "$tmp" >"$ENV_FILE"
	rm -f "$tmp"
}

get_env() {
	[ -f "$ENV_FILE" ] || return 0
	sed -n "s/^[[:space:]]*$1=//p" "$ENV_FILE" | tail -n1
}

url_origin() { # https://host:port/path -> https://host:port
	printf '%s' "$1" | sed -E 's#^([a-zA-Z][a-zA-Z0-9+.-]*://[^/]+).*#\1#'
}

pm2_running() {
	ps -eo args= 2>/dev/null | grep -q '^PM2 v[0-9].*God Daemon'
}

# ---------------------------------------------------------------- preflight
[ "$(id -u)" -eq 0 ] || die "run as root: sudo bash $0"
command -v systemctl >/dev/null 2>&1 || die "systemd is required."
command -v curl >/dev/null 2>&1 || die "curl is required."

if command -v apt-get >/dev/null 2>&1; then
	PM=apt
elif command -v dnf >/dev/null 2>&1; then
	PM=dnf
elif command -v yum >/dev/null 2>&1; then
	PM=yum
else
	die "unsupported OS: need apt-get, dnf, or yum."
fi

case "$(uname -m)" in
	x86_64 | amd64 | aarch64 | arm64) ;;
	*) die "unsupported CPU $(uname -m): packages exist for amd64 and arm64." ;;
esac

printf '\n%sDockBeacon installer%s\n\n' "$B" "$N"
if [ "$CHANNEL" = testing ]; then
	warn "TESTING channel: installs pre-release test builds. Use on test servers only."
fi

if ! command -v docker >/dev/null 2>&1; then
	warn "Docker is not installed. DockBeacon installs, but shows no containers until Docker runs here."
	confirm "Continue anyway?" y || exit 1
fi

# ------------------------------------------------------------------ package
if [ "$PM" = apt ]; then
	info "Adding the apt repository"
	curl -fsSL "$BASE_URL/install-apt.sh" | sh >/dev/null
	if dpkg -s "$PKG" >/dev/null 2>&1; then
		info "Upgrading $PKG"
		DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade \
			-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$PKG"
	else
		info "Installing $PKG"
		DEBIAN_FRONTEND=noninteractive apt-get install -y \
			-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$PKG"
	fi
else
	info "Adding the $PM repository"
	curl -fsSL "$BASE_URL/install-yum.sh" | sh >/dev/null
	if rpm -q "$PKG" >/dev/null 2>&1; then
		info "Upgrading $PKG"
		"$PM" upgrade -y --refresh "$PKG" || "$PM" upgrade -y "$PKG"
	else
		info "Installing $PKG"
		"$PM" install -y --refresh "$PKG" || "$PM" install -y "$PKG"
	fi
fi
[ -f "$ENV_FILE" ] || die "$ENV_FILE is missing after install."
installed_ver=$(dpkg-query -W -f='${Version}' "$PKG" 2>/dev/null || rpm -q --qf '%{VERSION}' "$PKG" 2>/dev/null || true)
if [ "$CHANNEL" = stable ]; then
	case "$installed_ver" in *~rc*) warn "test build $installed_ver stays installed until a newer stable release is out." ;; esac
fi

# ------------------------------------------------------------------ answers
FIRST_BOOT=1
[ -f "$DATA_DIR/users.json" ] && FIRST_BOOT=0

cur_mode=$(get_env APP_MODE); cur_mode=${cur_mode:-standalone}
printf '\n%sMode%s\n' "$B" "$N"
echo "  1) standalone - web UI on this host (control plane, or a single server)"
echo "  2) agent      - API only; another DockBeacon UI connects to this host"
mode_default=1; [ "$cur_mode" = agent ] && mode_default=2
case "${DLV_MODE:-}" in standalone) mode_default=1 ;; agent) mode_default=2 ;; esac
while :; do
	ask mode_choice "Choose 1 or 2" "$mode_default"
	case "$mode_choice" in
		1 | standalone) MODE=standalone; break ;;
		2 | agent) MODE=agent; break ;;
		*) echo "Enter 1 or 2." ;;
	esac
	[ "$YES" = "1" ] && die "DLV_MODE must be standalone or agent."
done

cur_name=$(get_env SERVER_NAME)
if [ -z "$cur_name" ] || [ "$cur_name" = docker-log-viewer ]; then
	cur_name=$(hostname -s 2>/dev/null || hostname)
fi
ask SERVER_NAME "Server name shown in the UI" "${DLV_SERVER_NAME:-$cur_name}"

cur_port=$(get_env PORT)
while :; do
	ask PORT "Port" "${DLV_PORT:-${cur_port:-9447}}"
	case "$PORT" in '' | *[!0-9]*) ;; *) [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] && break ;; esac
	echo "Enter a port between 1 and 65535."
	[ "$YES" = "1" ] && die "invalid DLV_PORT."
done

printf '\n%sHow will browsers reach this host?%s\n' "$B" "$N"
echo "  1) directly on http://<host>:$PORT     (LISTEN_ADDR=0.0.0.0)"
echo "  2) through nginx / a load balancer     (LISTEN_ADDR=127.0.0.1)"
cur_listen=$(get_env LISTEN_ADDR)
listen_default=1; [ "$cur_listen" = 127.0.0.1 ] && listen_default=2
case "${DLV_LISTEN_ADDR:-}" in 0.0.0.0) listen_default=1 ;; 127.0.0.1) listen_default=2 ;; esac
ask listen_choice "Choose 1 or 2" "$listen_default"
case "$listen_choice" in 2 | 127.0.0.1) LISTEN_ADDR=127.0.0.1 ;; *) LISTEN_ADDR=0.0.0.0 ;; esac

BASE_PATH=
if [ "$LISTEN_ADDR" = 127.0.0.1 ]; then
	echo "Serve under a URL prefix (for example /dockbeacon) when another site already uses /."
	ask BASE_PATH "URL prefix (blank for /)" "${DLV_BASE_PATH:-$(get_env BASE_PATH)}"
	if [ -n "$BASE_PATH" ]; then
		BASE_PATH="/${BASE_PATH#/}"
		BASE_PATH="${BASE_PATH%/}"
		case "$BASE_PATH" in *..* | *' '* | *\?* | *'#'*) die "invalid URL prefix: $BASE_PATH" ;; esac
	fi
fi

CONTROL_URL=
AUTH_SECRET=
if [ "$MODE" = agent ]; then
	printf '\n%sControl plane%s\n' "$B" "$N"
	echo "The URL of the standalone DockBeacon UI that will add this agent,"
	echo "for example https://logs.example.com/dockbeacon"
	cur_ui=$(get_env UI_URL)
	while :; do
		ask CONTROL_URL "Control plane URL" "${DLV_CONTROL_URL:-$cur_ui}"
		CONTROL_URL="${CONTROL_URL%/}"
		case "$CONTROL_URL" in http://?* | https://?*) break ;; esac
		echo "Enter a full URL starting with http:// or https://"
		[ "$YES" = "1" ] && die "DLV_CONTROL_URL is required for agent mode."
	done

	echo
	echo "Paste the control plane's signing secret so one login works on every host."
	echo "On the control plane, as root, it is AUTH_SECRET in $ENV_FILE,"
	echo "or else the contents of $DATA_DIR/users.json.secret"
	AUTH_SECRET="${DLV_AUTH_SECRET:-}"
	if [ -z "$AUTH_SECRET" ]; then
		ask_secret AUTH_SECRET "Secret (input hidden; blank keeps the current value)"
	fi
	if [ -z "$AUTH_SECRET" ] && [ -z "$(get_env AUTH_SECRET)" ]; then
		warn "no secret set. Users will have to sign in to this agent separately."
	fi
fi

# ------------------------------------------------------------------ write
backup="$ENV_FILE.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$ENV_FILE" "$backup"

set_env APP_MODE "$MODE"
set_env SERVER_NAME "$SERVER_NAME"
set_env PORT "$PORT"
set_env LISTEN_ADDR "$LISTEN_ADDR"
if [ -n "$BASE_PATH" ]; then set_env BASE_PATH "$BASE_PATH"; else unset_env BASE_PATH; fi
if [ "$MODE" = agent ]; then
	set_env CORS_ORIGINS "$(url_origin "$CONTROL_URL")"
	set_env UI_URL "$CONTROL_URL"
	if [ -n "$AUTH_SECRET" ]; then set_env AUTH_SECRET "$AUTH_SECRET"; fi
else
	unset_env CORS_ORIGINS
	unset_env UI_URL
fi
chown root:docker-log-viewer "$ENV_FILE" 2>/dev/null || true
chmod 0640 "$ENV_FILE"
info "Wrote $ENV_FILE (previous copy: $backup)"

# ------------------------------------------------------------------ PM2
if pm2_running; then
	info "PM2 is running here; granting log and control access"
	if ! command -v setfacl >/dev/null 2>&1; then
		if [ "$PM" = apt ]; then
			DEBIAN_FRONTEND=noninteractive apt-get install -y acl >/dev/null
		else
			"$PM" install -y acl >/dev/null
		fi
	fi
	if [ ! -x "$GRANT" ] || ! "$GRANT"; then
		warn "PM2 grant failed. Re-run: sudo $GRANT"
	fi
fi

# ------------------------------------------------------------------ start
info "Starting $SERVICE"
systemctl daemon-reload
systemctl enable "$SERVICE" >/dev/null 2>&1
systemctl restart "$SERVICE"

ok=0
for _ in $(seq 1 20); do
	if curl -fsS -o /dev/null "http://127.0.0.1:$PORT$BASE_PATH/api/info"; then ok=1; break; fi
	sleep 1
done
if [ "$ok" != 1 ]; then
	journalctl -u "$SERVICE" -n 30 --no-pager >&2 || true
	die "$SERVICE did not answer on 127.0.0.1:$PORT$BASE_PATH. Logs are above."
fi
info "$SERVICE is running ($(rpm -q "$PKG" 2>/dev/null || dpkg-query -W -f='${Package} ${Version}' "$PKG" 2>/dev/null))"

# ------------------------------------------------------------------ summary
host_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
host_ip=${host_ip:-<host>}
printf '\n%sDone.%s\n' "$B" "$N"

if [ "$LISTEN_ADDR" = 0.0.0.0 ]; then
	echo "URL: http://$host_ip:$PORT$BASE_PATH/   (open port $PORT in the firewall / security group)"
else
	loc=${BASE_PATH:-}/
	cat <<EOF
DockBeacon listens on 127.0.0.1:$PORT. Add this to your nginx server block
(HTTPS site), then run: nginx -t && systemctl reload nginx

    location $loc {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600s;
        proxy_buffering off;
    }
EOF
fi

if [ "$MODE" = standalone ]; then
	if [ "$FIRST_BOOT" = 1 ]; then
		pass_line=$(journalctl -u "$SERVICE" --no-pager -o cat 2>/dev/null | grep 'generated temporary password' | tail -n1 || true)
		if [ -n "$pass_line" ]; then
			echo "Sign in as admin with: ${pass_line##*: }"
			echo "Change it in Settings after the first sign-in."
		fi
	fi
	echo "To add agents: Settings -> Servers. Give each agent this host's secret"
	echo "(AUTH_SECRET in $ENV_FILE, or $DATA_DIR/users.json.secret)."
else
	echo "On the control plane: Settings -> Servers -> add this agent's URL, then Test."
fi
echo "Config: $ENV_FILE   Logs: journalctl -u $SERVICE -f"
