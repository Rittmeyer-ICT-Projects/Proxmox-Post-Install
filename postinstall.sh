#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok()   { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error(){ echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

header_info() { clear; cat <<"EOF"
    ____ _    ________   ____             __     ____           __        ____
   / __ \ |  / / ____/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / | / / __/    / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / ____/| |/ / /___   / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/     |___/_____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/
EOF
}

if ! pveversion | grep -Eq "pve-manager/8.[0-3]"; then
  msg_error "Unsupported PVE Version"; exit 1
fi

header_info
msg_info "Correcting Sources"
cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf
msg_ok "Sources Corrected"

if [[ "${1:-}" == "--enterprise" ]]; then
  msg_info "Enabling Enterprise Repository"
  echo "deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" >/etc/apt/sources.list.d/pve-enterprise.list
  msg_ok "Enterprise Enabled"
else
  msg_info "Disabling Enterprise Repository, Enabling No-Subscription"
  echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" >/etc/apt/sources.list.d/pve-enterprise.list
  echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >/etc/apt/sources.list.d/pve-install-repo.list
  msg_ok "Enterprise Disabled, No-Subscription Enabled"
fi

msg_info "Correcting Ceph Repos"
cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
# deb https://enterprise.proxmox.com/debian/ceph-reef bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF
msg_ok "Ceph Repos Corrected"

msg_info "Skipping pvetest (no changes)"
msg_ok "Skipped pvetest"

if [[ ! -f /etc/apt/apt.conf.d/no-nag-script ]]; then
  msg_info "Disabling Subscription Nag"
  echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
  apt --reinstall install proxmox-widget-toolkit &>/dev/null
  msg_ok "Nag Disabled"
fi

if ! systemctl is-active --quiet pve-ha-lrm; then
  msg_info "Enabling HA"
  systemctl enable -q --now pve-ha-lrm pve-ha-crm corosync
  msg_ok "HA Enabled"
fi

msg_info "Not Disabling HA (skipped)"

msg_info "Updating Proxmox VE"
apt-get update &>/dev/null
apt-get -y dist-upgrade &>/dev/null
msg_ok "Proxmox VE Updated"

msg_info "Skipping Reboot (recommended to reboot manually)"
msg_ok "Done"

msg_info "Setting up automatic config backup"
(crontab -l 2>/dev/null; echo "0 8 * * 7 mkdir -p \"\$(awk '/^[[:space:]]*path[[:space:]]+\\/mnt\\/pve\\/.*NAS01/ {print \$2}' /etc/pve/storage.cfg)/ProxmoxConfigBackup\" && tar czf \"\$(awk '/^[[:space:]]*path[[:space:]]+\\/mnt\\/pve\\/.*NAS01/ {print \$2}' /etc/pve/storage.cfg)/ProxmoxConfigBackup/proxmox_backup_\$(date +%Y%m%d_%H%M%S).tar.gz\" -C /etc/pve .") | crontab -

msg_info "Setting up the LXC notes script"
curl -fsSL -o /usr/local/bin/update-lxc-notes.sh https://raw.githubusercontent.com/Rittmeyer-ICT-Projects/Proxmox-Post-Install-Script/main/update-lxc-notes.sh && chmod +x /usr/local/bin/update-lxc-notes.sh && (crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/update-lxc-notes.sh >/dev/null 2>&1") | crontab -
