# Proxmox VE Post Install Scripts

This repository contains two Proxmox VE post-install scripts to automate common setup tasks. These scripts are based on the original work by [tteck](https://github.com/tteck), with modifications to suit specific needs.

## Script Descriptions

### Script 1: `proxmox-post-install-no-subscription.sh`
This Script is for Proxmox Hosts, who will receive no commercial subscription.

This script performs the following actions:
- Corrects the Proxmox VE sources.
- Disables the 'pve-enterprise' repository.
- Enables the 'pve-no-subscription' repository.
- Disables the subscription nag message.
- Updates Proxmox VE to the latest version.
- Reboots the Proxmox VE host.

### Script 2: `proxmox-post-install-with-subscription.sh`
This Script is for Proxmox Hosts, who will receive a commercial subscription.

This script performs the following actions:
- Corrects the Proxmox VE sources.
- Enables the 'pve-enterprise' repository.
- Disables the subscription nag message.
- Updates Proxmox VE to the latest version.
- Reboots the Proxmox VE host.

## Usage

Copy this command to the Proxmox shell, and everything will run automatically.
Script for machines without subscription: `bash -c "$(wget -qLO - https://raw.githubusercontent.com/Rittmeyer-ICT-Projects/Proxmox-Post-Install-Script/main/proxmox-post-install-no-subscription.sh) "`
Script for machines with subscription: `bash -c "$(wget -qLO - https://raw.githubusercontent.com/Rittmeyer-ICT-Projects/Proxmox-Post-Install-Script/main/proxmox-post-install-with-subscription.sh) "`

## Credits

These scripts are based on the original work by [tteck](https://github.com/tteck). Full credit goes to tteck for the initial implementation and inspiration.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

