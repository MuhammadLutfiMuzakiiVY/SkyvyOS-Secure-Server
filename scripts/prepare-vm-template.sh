#!/bin/bash

################################################################################
# SkyvyOS Server - VM Template Preparation Script
#
# This script prepares SkyvyOS Server for conversion to a VM template
# Compatible with any virtualization platform (KVM, VMware, VirtualBox, etc.)
# Run this before converting your VM to a template
#
# Usage: sudo ./prepare-vm-template.sh
################################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SkyvyOS VM Template Preparation Script          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Please run as root${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[1/10] Stopping services...${NC}"
systemctl stop nginx || true
systemctl stop docker || true
systemctl stop fail2ban || true

echo -e "${GREEN}[2/10] Cleaning package cache...${NC}"
apt-get clean
apt-get autoclean
apt-get autoremove -y

echo -e "${GREEN}[3/10] Clearing temporary files...${NC}"
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/apt/archives/*.deb

echo -e "${GREEN}[4/10] Removing SSH host keys...${NC}"
rm -f /etc/ssh/ssh_host_*

echo -e "${GREEN}[5/10] Clearing machine-id...${NC}"
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo -e "${GREEN}[6/10] Clearing shell history...${NC}"
history -c
cat /dev/null > ~/.bash_history
rm -f /root/.bash_history
find /home -name .bash_history -delete

echo -e "${GREEN}[7/10] Clearing log files...${NC}"
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
truncate -s 0 /var/log/wtmp
truncate -s 0 /var/log/lastlog

echo -e "${GREEN}[8/10] Removing cloud-init artifacts...${NC}"
cloud-init clean --logs --seed || true

echo -e "${GREEN}[9/10] Installing cloud-init for VM automation...${NC}"
apt-get update
apt-get install -y cloud-init qemu-guest-agent

# Configure cloud-init for generic VM use
cat > /etc/cloud/cloud.cfg.d/99-custom.cfg <<EOF
datasource_list: [NoCloud, ConfigDrive, OpenStack, None]
datasource:
  NoCloud:
    fs_label: cidata
EOF

systemctl enable qemu-guest-agent

echo -e "${GREEN}[10/10] Final cleanup...${NC}"
sync

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Template Preparation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Shutdown this VM: ${YELLOW}shutdown -h now${NC}"
echo "  2. In your virtualization platform:"
echo "     - Convert VM to template/master image"
echo "     - Take snapshot for cloning"
echo "  3. To deploy from template:"
echo "     - Clone/copy the VM"
echo "     - Boot the new instance"
echo ""
echo -e "${BLUE}Cloud-init Configuration:${NC}"
echo "  • cloud-init installed for automation"
echo "  • SSH keys will be regenerated on first boot"
echo "  • machine-id will be regenerated"
echo "  • Compatible with most cloud/VM platforms"
echo ""
echo -e "${YELLOW}Ready to shutdown and convert to template!${NC}"
echo ""
