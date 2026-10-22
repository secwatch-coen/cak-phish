#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '\n[install] %s\n' "$*"
}

fatal() {
  printf '\n[install] ERROR: %s\n' "$*" >&2
  exit 1
}

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  fatal "Please run as sudo (e.g. sudo ./install.sh)."
fi

TARGET_USER="${SUDO_USER:-${USER:-}}"
if [ -z "$TARGET_USER" ]; then
  fatal "Unable to determine target user. Run with sudo from the desired user."
fi
if [ "$TARGET_USER" = "root" ]; then
  fatal "SUDO_USER is not set and current user is root. Run with sudo from the desired user to grant sudo and docker group access."
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [ -z "$TARGET_HOME" ]; then
  fatal "Unable to determine home directory for $TARGET_USER."
fi

log "Installing base packages (iptables, curl, gnupg, ca-certificates, screen, net-tools)."
apt-get update -y
apt-get install -y iptables curl gnupg ca-certificates screen net-tools openssh-client

log "Configuring Docker CE repository."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

log "Installing Docker CE packages."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Allowing $TARGET_USER to run Docker without sudo."
usermod -aG docker "$TARGET_USER"

log "Fetching Cloudflare IP ranges."
CF_IPS_V4="$(curl -fsSL https://www.cloudflare.com/ips-v4)"
CF_IPS_V6="$(curl -fsSL https://www.cloudflare.com/ips-v6)"

log "Writing Cloudflare IP ranges for firewall management."
install -d -m 0755 /etc/spear-phishing-framework
cat > /etc/spear-phishing-framework/cloudflare-ips-v4.txt <<EOF
$CF_IPS_V4
EOF
cat > /etc/spear-phishing-framework/cloudflare-ips-v6.txt <<EOF
$CF_IPS_V6
EOF

log "Installing iptables firewall script for SSH and Cloudflare-only HTTP/HTTPS."
cat > /usr/local/sbin/spf-apply-firewall.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CF_V4_FILE="/etc/spear-phishing-framework/cloudflare-ips-v4.txt"
CF_V6_FILE="/etc/spear-phishing-framework/cloudflare-ips-v6.txt"
INPUT_CHAIN="SPF-CF-INPUT"
DOCKER_CHAIN="SPF-CF-DOCKER"

ensure_chain() {
  local cmd="$1"
  local chain="$2"

  if ! "$cmd" -w -nL "$chain" >/dev/null 2>&1; then
    "$cmd" -w -N "$chain"
  fi
}

ensure_rule() {
  local cmd="$1"
  local chain="$2"
  local position="$3"
  shift 3

  if ! "$cmd" -w -C "$chain" "$@" >/dev/null 2>&1; then
    "$cmd" -w -I "$chain" "$position" "$@"
  fi
}

populate_cloudflare_chain() {
  local cmd="$1"
  local chain="$2"
  local source_file="$3"

  "$cmd" -w -F "$chain"

  while IFS= read -r cidr; do
    [ -n "$cidr" ] || continue
    "$cmd" -w -A "$chain" -p tcp -m multiport --dports 80,443 -s "$cidr" -j ACCEPT
  done < "$source_file"

  "$cmd" -w -A "$chain" -p tcp -m multiport --dports 80,443 -j DROP
}

configure_input_chain() {
  local cmd="$1"
  local icmp_proto="$2"
  local source_file="$3"

  ensure_chain "$cmd" "$INPUT_CHAIN"
  populate_cloudflare_chain "$cmd" "$INPUT_CHAIN" "$source_file"

  ensure_rule "$cmd" INPUT 1 -p tcp -m multiport --dports 80,443 -j "$INPUT_CHAIN"
  ensure_rule "$cmd" INPUT 1 -p tcp --dport 22 -j ACCEPT
  ensure_rule "$cmd" INPUT 1 -p "$icmp_proto" -j ACCEPT
  ensure_rule "$cmd" INPUT 1 -i lo -j ACCEPT
  ensure_rule "$cmd" INPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  "$cmd" -w -P INPUT DROP
  "$cmd" -w -P OUTPUT ACCEPT
}

configure_docker_user_chain() {
  local cmd="$1"
  local source_file="$2"

  ensure_chain "$cmd" DOCKER-USER
  ensure_chain "$cmd" "$DOCKER_CHAIN"
  populate_cloudflare_chain "$cmd" "$DOCKER_CHAIN" "$source_file"

  if ! "$cmd" -w -C DOCKER-USER -j RETURN >/dev/null 2>&1; then
    "$cmd" -w -A DOCKER-USER -j RETURN
  fi

  ensure_rule "$cmd" DOCKER-USER 1 -p tcp -m multiport --dports 80,443 -j "$DOCKER_CHAIN"
  ensure_rule "$cmd" DOCKER-USER 1 -i br+ -j RETURN
  ensure_rule "$cmd" DOCKER-USER 1 -i docker+ -j RETURN
  ensure_rule "$cmd" DOCKER-USER 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
}

configure_input_chain iptables icmp "$CF_V4_FILE"
configure_input_chain ip6tables ipv6-icmp "$CF_V6_FILE"
configure_docker_user_chain iptables "$CF_V4_FILE"
configure_docker_user_chain ip6tables "$CF_V6_FILE"
EOF
chmod 0755 /usr/local/sbin/spf-apply-firewall.sh

log "Installing systemd units to reapply firewall rules on boot and Docker restart."
install -d -m 0755 /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/spf-firewall.service <<'EOF'
[Unit]
Description=Apply spear-phishing-framework firewall rules
ConditionPathExists=/usr/local/sbin/spf-apply-firewall.sh
Before=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/spf-apply-firewall.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/docker.service.d/10-spf-firewall.conf <<'EOF'
[Service]
ExecStartPost=/usr/local/sbin/spf-apply-firewall.sh
EOF

systemctl daemon-reload
systemctl enable --now docker
systemctl enable --now spf-firewall.service
/usr/local/sbin/spf-apply-firewall.sh

log "Hardening SSH (disallow root login)."
if [ -f /etc/ssh/sshd_config ]; then
  if grep -qE '^[# ]*PermitRootLogin' /etc/ssh/sshd_config; then
    sed -i 's/^[# ]*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  else
    printf '\nPermitRootLogin no\n' >> /etc/ssh/sshd_config
  fi

  if systemctl list-unit-files | awk '{print $1}' | grep -q '^ssh\.service$'; then
    systemctl reload ssh || systemctl restart ssh
  elif systemctl list-unit-files | awk '{print $1}' | grep -q '^sshd\.service$'; then
    systemctl reload sshd || systemctl restart sshd
  fi
else
  log "Warning: /etc/ssh/sshd_config not found; skipping SSH hardening."
fi

log "Done. Log out and back in for group changes to take effect."
