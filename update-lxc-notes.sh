#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NODE=$(hostname)

# Loop through all LXC container IDs on this node
for VMID in $(pct list | awk 'NR>1 {print $1}'); do
  # Retrieve primary IPv4 address of the container
  IP=$(
    pct exec "$VMID" -- \
      ip -4 addr show scope global \
      | awk '/inet / {print $2}' \
      | cut -d/ -f1 \
      | head -n1
  )

  # Skip if no IP found for this container
  if [ -z "$IP" ]; then
    echo "No IP found for container $VMID. Skipping."
    continue
  fi

  # Retrieve netmask (CIDR notation)
  NETMASK=$(
    pct exec "$VMID" -- \
      ip -4 addr show scope global \
      | awk '/inet / {split($2,a,"/"); print a[2]; exit}'
  )

  # Retrieve default gateway
  GATEWAY=$(
    pct exec "$VMID" -- \
      ip route | awk '/default/ {print $3; exit}'
  )

  # Retrieve first DNS server from resolv.conf
  DNS=$(
    pct exec "$VMID" -- \
      grep -m1 '^nameserver' /etc/resolv.conf | awk '{print $2}'
  )

  # Retrieve additional container details
  HOSTNAME=$(pct exec "$VMID" -- hostname 2>/dev/null)
  OS_VERSION=$(
    pct exec "$VMID" -- bash -c 'grep ^PRETTY_NAME= /etc/os-release 2>/dev/null' \
      | cut -d= -f2 \
      | tr -d '"'
  )
  UPTIME=$(pct exec "$VMID" -- uptime -p 2>/dev/null)
  REBOOT_REQUIRED=$(
    pct exec "$VMID" -- bash -c 'test -f /var/run/reboot-required && echo "Yes" || echo "No"'
  )

  # Construct HTML table for description
  DESCRIPTION="<table border=\"1\" style=\"border-collapse:collapse;\">
<h3>${HOSTNAME}</h3>
<tr><td>OS Version</td><td>${OS_VERSION}</td></tr>
<tr><td>Uptime</td><td>${UPTIME}</td></tr>
<tr><td>IP</td><td>${IP}</td></tr>
<tr><td>Netmask</td><td>/${NETMASK}</td></tr>
<tr><td>Gateway</td><td>${GATEWAY}</td></tr>
<tr><td>DNS</td><td>${DNS}</td></tr>
<tr><td>Reboot Required</td><td>${REBOOT_REQUIRED}</td></tr>
</table>"

  # Update the container's description (Notes field) with HTML
  pvesh set /nodes/"$NODE"/lxc/"$VMID"/config --description "$DESCRIPTION"

  if [ $? -eq 0 ]; then
    echo "Updated container $VMID with network details:"
    echo "$DESCRIPTION"
  else
    echo "Failed to update container $VMID."
  fi
done
