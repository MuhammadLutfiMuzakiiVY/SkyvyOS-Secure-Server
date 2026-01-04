#!/bin/bash

################################################################################
# SkyvyOS Server - Security Hardening Script
#
# This script applies comprehensive security hardening to the system
# Can be run standalone or as part of the main installation
#
# Usage: sudo ./security-hardening.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[ℹ] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[⚠] $1${NC}"
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SkyvyOS Security Hardening Script   ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"

# 1. SSH Hardening
print_step "Hardening SSH configuration..."

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/99-skyvyos-hardening.conf <<EOF
# SkyvyOS SSH Security Hardening

# Network
Port 22
AddressFamily any
ListenAddress 0.0.0.0

# Protocol
Protocol 2

# Authentication
LoginGraceTime 60
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 10
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Disable unused authentication methods
HostbasedAuthentication no
IgnoreRhosts yes
KerberosAuthentication no
GSSAPIAuthentication no

# Security features
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 2
UseDNS no
PermitUserEnvironment no
AllowAgentForwarding yes
AllowTcpForwarding yes
PermitTunnel no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# File transfer
Subsystem sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO
EOF

systemctl restart sshd
print_info "SSH hardened - password auth disabled, root login disabled"

# 2. Firewall (UFW)
print_step "Configuring UFW firewall..."

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw logging on

# Essential services
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Enable firewall
ufw --force enable

print_info "Firewall configured with default deny policy"

# 3. Fail2ban
print_step "Configuring fail2ban..."

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
# Ban duration in seconds
bantime = 3600

# Time window for detection
findtime = 600

# Max retries before ban
maxretry = 5

# Email settings
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail

# Action
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

systemctl enable fail2ban
systemctl restart fail2ban

print_info "fail2ban configured for SSH and Nginx protection"

# 4. Kernel Security (sysctl)
print_step "Applying kernel security hardening..."

cat > /etc/sysctl.d/99-skyvyos-security.conf <<EOF
# SkyvyOS Kernel Security Hardening

# Network Security
# -----------------

# IP Forwarding (disable unless needed for routing/Docker)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# IP Spoofing Protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Do not send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore ICMP ping requests (optional - uncomment to enable)
# net.ipv4.icmp_echo_ignore_all = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log suspicious packets (Martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Disable IPv6 Router Advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# TCP Hardening
# --------------
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Kernel Hardening
# -----------------

# Restrict kernel log access
kernel.dmesg_restrict = 1

# Hide kernel pointers
kernel.kptr_restrict = 2

# Restrict ptrace scope
kernel.yama.ptrace_scope = 1

# Restrict access to kernel performance events
kernel.perf_event_paranoid = 3

# File System Hardening
# ----------------------

# Protect hardlinks and symlinks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Restrict core dumps
fs.suid_dumpable = 0

# Increase inotify watches (for monitoring tools)
fs.inotify.max_user_watches = 524288

# Memory & Process
# -----------------

# Virtual memory tuning
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Address space layout randomization
kernel.randomize_va_space = 2
EOF

sysctl -p /etc/sysctl.d/99-skyvyos-security.conf > /dev/null 2>&1

print_info "Kernel security parameters applied"

# 5. File Permissions
print_step "Setting secure file permissions..."

# Secure sensitive files
chmod 600 /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/shadow
chmod 600 /etc/gshadow

print_info "File permissions secured"

# 6. Disable Unnecessary Services
print_step "Disabling unnecessary services..."

# List of services to disable if they exist
SERVICES_TO_DISABLE=(
    "bluetooth"
    "cups"
    "avahi-daemon"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled "$service" 2>/dev/null | grep -q enabled; then
        systemctl disable "$service" 2>/dev/null || true
        systemctl stop "$service" 2>/dev/null || true
        print_info "Disabled $service"
    fi
done

# 7. Set Proper umask
print_step "Setting secure umask..."

# Set umask in /etc/login.defs
if grep -q "^UMASK" /etc/login.defs; then
    sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
else
    echo "UMASK 027" >> /etc/login.defs
fi

# Set umask in profile
if ! grep -q "umask 027" /etc/profile; then
    echo "umask 027" >> /etc/profile
fi

print_info "Umask set to 027 for enhanced security"

# 8. Automatic Security Updates
print_step "Configuring automatic security updates..."

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

print_info "Automatic security updates enabled"

# 9. Network Security Limits
print_step "Configuring system limits..."

cat > /etc/security/limits.d/99-skyvyos.conf <<EOF
# SkyvyOS System Limits

# Core dumps
* hard core 0

# File descriptors
* soft nofile 65535
* hard nofile 65535

# Max processes
* soft nproc 32768
* hard nproc 32768

# Max locked memory
* soft memlock unlimited
* hard memlock unlimited
EOF

print_info "System limits configured"

# 10. Disable USB Storage (optional - uncomment if needed)
# print_step "Disabling USB storage..."
# echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb-storage.conf

# 11. Audit installed packages
print_step "Creating security audit script..."

cat > /usr/local/bin/skyvy-security-audit <<'EOF'
#!/bin/bash

echo "SkyvyOS Security Audit Report"
echo "=============================="
echo ""
echo "1. SSH Configuration:"
echo "   - Root login: $(grep "^PermitRootLogin" /etc/ssh/sshd_config.d/*.conf 2>/dev/null || echo 'not set')"
echo "   - Password auth: $(grep "^PasswordAuthentication" /etc/ssh/sshd_config.d/*.conf 2>/dev/null || echo 'not set')"
echo ""
echo "2. Firewall Status:"
sudo ufw status numbered
echo ""
echo "3. Fail2ban Status:"
sudo fail2ban-client status
echo ""
echo "4. Open Ports:"
sudo ss -tulpn | grep LISTEN
echo ""
echo "5. Failed Login Attempts:"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 || echo "No recent failed attempts"
echo ""
echo "6. Security Updates Available:"
apt list --upgradable 2>/dev/null | grep -i security || echo "None"
EOF

chmod +x /usr/local/bin/skyvy-security-audit

print_info "Security audit script created: skyvy-security-audit"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    SkyvyOS Security Hardening Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Applied Security Measures:${NC}"
echo "  ✓ SSH hardened (key-only auth, no root login)"
echo "  ✓ UFW firewall configured and enabled"
echo "  ✓ fail2ban protecting SSH and Nginx"
echo "  ✓ Kernel security parameters optimized"
echo "  ✓ Automatic security updates enabled"
echo "  ✓ File permissions secured"
echo "  ✓ System limits configured"
echo "  ✓ Unnecessary services disabled"
echo ""
echo -e "${YELLOW}Important Reminders:${NC}"
echo "  ⚠  Make sure you have SSH keys configured!"
echo "  ⚠  Test SSH connection before closing this session"
echo "  ⚠  Password authentication is now DISABLED"
echo ""
echo -e "${BLUE}Security Tools:${NC}"
echo "  • Run security audit: ${GREEN}skyvy-security-audit${NC}"
echo "  • Check firewall: ${GREEN}sudo ufw status${NC}"
echo "  • Check fail2ban: ${GREEN}sudo fail2ban-client status${NC}"
echo ""
