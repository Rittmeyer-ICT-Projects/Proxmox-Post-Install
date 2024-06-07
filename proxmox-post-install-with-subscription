#!/usr/bin/env bash

# Condensed Proxmox Post Install Script, boiled down by Oliver Corrodi (Rittmeyer AG).
# Hard coded for Servers who have a Proxmox subscription.
# Based upon copyrighted work by tteck (tteckster), 2021-2024. https://github.com/tteck/Proxmox/raw/main/LICENSE
# License: MIT

# Correct Proxmox VE Sources
cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf

# Enable 'pve-enterprise' repository
cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF

# Disable 'pve-no-subscription' repository
cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
# deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Disable subscription nag
if [[ ! -f /etc/apt/apt.conf.d/no-nag-script ]]; then
    echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
    apt --reinstall install proxmox-widget-toolkit &>/dev/null
fi

# Update Proxmox VE
echo "Updating now - please wait - machine will reboot upon completion
apt-get update &>/dev/null
apt-get -y dist-upgrade &>/dev/null

# Reboot Proxmox VE
reboot
