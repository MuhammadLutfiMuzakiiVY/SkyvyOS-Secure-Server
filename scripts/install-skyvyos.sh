#!/bin/bash

################################################################################
# SkyvyOS Server - Automated Installation Script
# 
# This script transforms a Debian minimal installation into SkyvyOS Server
# 
# Requirements: Fresh Debian 12 (Bookworm) minimal installation
# Usage: sudo ./install-skyvyos.sh
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Branding
BANNER="
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     ███████╗██╗  ██╗██╗   ██╗██╗   ██╗██╗   ██╗         ║
║     ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║   ██║╚██╗ ██╔╝         ║
║     ███████╗█████╔╝  ╚████╔╝ ██║   ██║ ╚████╔╝          ║
║     ╚════██║██╔═██╗   ╚██╔╝  ╚██╗ ██╔╝  ╚██╔╝           ║
║     ███████║██║  ██╗   ██║    ╚████╔╝    ██║            ║
║     ╚══════╝╚═╝  ╚═╝   ╚═╝     ╚═══╝     ╚═╝            ║
║                                                           ║
║               SkyvyOS Server Installer                    ║
║            Custom Debian-based Server OS                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
"

# Functions
print_header() {
    echo -e "${BLUE}${BANNER}${NC}"
}

print_step() {
    echo -e "\n${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[ℹ] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[⚠] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root or with sudo"
        exit 1
    fi
}

check_debian() {
    if [ ! -f /etc/debian_version ]; then
        print_error "This script is designed for Debian-based systems"
        exit 1
    fi
    
    print_info "Detected Debian version: $(cat /etc/debian_version)"
}

backup_config() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up: $file"
    fi
}

# Main installation functions

update_system() {
    print_step "Updating system packages..."
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
}

install_base_packages() {
    print_step "Installing base system packages..."
    
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        tmux \
        net-tools \
        dnsutils \
        iputils-ping
}

install_security_packages() {
    print_step "Installing security packages..."
    
    apt-get install -y \
        ufw \
        fail2ban \
        unattended-upgrades \
        apt-listchanges \
        openssh-server \
        sudo
}

install_web_server() {
    print_step "Installing Nginx web server..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
}

install_docker() {
    print_step "Installing Docker..."
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    systemctl enable docker
    systemctl start docker
    
    print_info "Docker installed successfully"
}

install_nodejs() {
    print_step "Installing Node.js LTS..."
    
    # Install Node.js 20.x LTS from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    print_info "Node.js version: $(node --version)"
    print_info "npm version: $(npm --version)"
}

install_python() {
    print_step "Installing Python 3..."
    
    apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools
    
    print_info "Python version: $(python3 --version)"
}

install_php() {
    print_step "Installing PHP..."
    
    apt-get install -y \
        php \
        php-fpm \
        php-cli \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip
    
    systemctl enable php*-fpm || true
    systemctl start php*-fpm || true
    
    print_info "PHP version: $(php --version | head -n 1)"
}

install_certbot() {
    print_step "Installing Certbot for SSL certificates..."
    apt-get install -y certbot python3-certbot-nginx
}

install_utilities() {
    print_step "Installing additional utilities..."
    
    apt-get install -y \
        tree \
        rsync \
        zip \
        unzip \
        tar \
        gzip \
        bzip2 \
        xz-utils \
        build-essential \
        sysstat \
        iotop \
        logrotate \
        rsyslog \
        cron \
        jq \
        ncdu \
        lsof
}

configure_firewall() {
    print_step "Configuring UFW firewall..."
    
    # Reset UFW to default
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp comment 'SSH'
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    
    # Enable UFW
    ufw --force enable
    
    print_info "Firewall configured and enabled"
}

configure_fail2ban() {
    print_step "Configuring fail2ban..."
    
    # Create local jail configuration
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
    
    print_info "fail2ban configured and started"
}

configure_ssh() {
    print_step "Hardening SSH configuration..."
    
    backup_config /etc/ssh/sshd_config
    
    # SSH hardening
    cat > /etc/ssh/sshd_config.d/skyvyos-hardening.conf <<EOF
# SkyvyOS SSH Hardening Configuration
Port 22
Protocol 2

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Security
X11Forwarding no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
EOF

    print_warning "SSH password authentication has been DISABLED"
    print_warning "Make sure you have added your SSH public key before rebooting!"
    print_warning "To add your key: mkdir -p ~/.ssh && nano ~/.ssh/authorized_keys"
    
    systemctl restart sshd
}

configure_automatic_updates() {
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
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    print_info "Automatic security updates enabled"
}

apply_sysctl_hardening() {
    print_step "Applying kernel security hardening..."
    
    cat > /etc/sysctl.d/99-skyvyos-hardening.conf <<EOF
# SkyvyOS Kernel Security Hardening

# IP Forwarding (disabled for security, enable if needed for Docker/routing)
net.ipv4.ip_forward = 0

# Disable IPv6 if not needed
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Do not send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore ICMP pings
# net.ipv4.icmp_echo_ignore_all = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Kernel hardening
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# File system hardening
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF

    sysctl -p /etc/sysctl.d/99-skyvyos-hardening.conf > /dev/null
    print_info "Kernel security parameters applied"
}

setup_branding() {
    print_step "Setting up SkyvyOS branding..."
    
    # Create /etc/os-release
    cat > /etc/os-release <<EOF
NAME="SkyvyOS Server"
VERSION="Stable"
ID=skyvyos
ID_LIKE=debian
PRETTY_NAME="SkyvyOS Server"
VERSION_ID="stable"
VERSION_CODENAME=stable
HOME_URL="https://skyvy.os"
SUPPORT_URL="https://skyvy.os/support"
BUG_REPORT_URL="https://skyvy.os/bugs"
LOGO=debian-logo
EOF

    # Create MOTD
    cat > /etc/motd <<'EOF'

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     ███████╗██╗  ██╗██╗   ██╗██╗   ██╗██╗   ██╗         ║
║     ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║   ██║╚██╗ ██╔╝         ║
║     ███████╗█████╔╝  ╚████╔╝ ██║   ██║ ╚████╔╝          ║
║     ╚════██║██╔═██╗   ╚██╔╝  ╚██╗ ██╔╝  ╚██╔╝           ║
║     ███████║██║  ██╗   ██║    ╚████╔╝    ██║            ║
║     ╚══════╝╚═╝  ╚═╝   ╚═╝     ╚═══╝     ╚═╝            ║
║                                                           ║
║                   SkyvyOS Server                          ║
║          Lightweight • Secure • Production Ready          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Welcome to SkyvyOS Server - Built for Stability and Performance

EOF

    # Create issue (pre-login banner)
    cat > /etc/issue <<'EOF'
SkyvyOS Server - \n \l

EOF

    print_info "SkyvyOS branding installed"
}

create_welcome_script() {
    print_step "Creating system info script..."
    
    cat > /usr/local/bin/skyvy-info <<'EOF'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     ${GREEN}SkyvyOS Server Information${NC}      ${BLUE}║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC} Hostname: $(hostname)                  "
echo -e "${BLUE}║${NC} Uptime: $(uptime -p | sed 's/up //')   "
echo -e "${BLUE}║${NC} Load: $(uptime | awk -F'load average:' '{print $2}')  "
echo -e "${BLUE}║${NC} Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')  "
echo -e "${BLUE}║${NC} Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')  "
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
EOF

    chmod +x /usr/local/bin/skyvy-info
    
    # Add to bash profile for login info
    echo "" >> /etc/bash.bashrc
    echo "# SkyvyOS System Info" >> /etc/bash.bashrc
    echo "/usr/local/bin/skyvy-info 2>/dev/null" >> /etc/bash.bashrc
}

cleanup() {
    print_step "Cleaning up..."
    apt-get autoremove -y
    apt-get autoclean -y
    apt-get clean
}

installation_complete() {
    clear
    print_header
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          SKYVYOS SERVER INSTALLATION COMPLETE!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}System Information:${NC}"
    echo -e "  • OS: SkyvyOS Server"
    echo -e "  • Base: Debian $(cat /etc/debian_version)"
    echo -e "  • Kernel: $(uname -r)"
    
    echo -e "\n${BLUE}Installed Services:${NC}"
    echo -e "  • Web Server: Nginx"
    echo -e "  • Container Platform: Docker"
    echo -e "  • Runtime: Node.js $(node --version 2>/dev/null || echo 'N/A')"
    echo -e "  • Runtime: Python $(python3 --version 2>/dev/null | awk '{print $2}' || echo 'N/A')"
    echo -e "  • Runtime: PHP $(php --version 2>/dev/null | head -n1 | awk '{print $2}' || echo 'N/A')"
    
    echo -e "\n${BLUE}Security Status:${NC}"
    echo -e "  • Firewall (UFW): ${GREEN}ACTIVE${NC}"
    echo -e "  • Fail2ban: ${GREEN}RUNNING${NC}"
    echo -e "  • SSH: ${GREEN}HARDENED${NC}"
    echo -e "  • Auto Updates: ${GREEN}ENABLED${NC}"
    
    echo -e "\n${YELLOW}Important Notes:${NC}"
    echo -e "  ⚠  SSH password authentication is DISABLED"
    echo -e "  ⚠  Only SSH key authentication is allowed"
    echo -e "  ⚠  Root SSH login is DISABLED"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo -e "  1. Add your SSH public key to ~/.ssh/authorized_keys"
    echo -e "  2. Test SSH connection before closing this session"
    echo -e "  3. Reboot the system: ${GREEN}sudo reboot${NC}"
    echo -e "  4. Configure your applications and services"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  • System info: ${GREEN}skyvy-info${NC}"
    echo -e "  • Firewall status: ${GREEN}sudo ufw status${NC}"
    echo -e "  • Service status: ${GREEN}sudo systemctl status SERVICE${NC}"
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "Installation log saved to: /var/log/skyvyos-install.log"
    print_info "System is ready for production use!"
}

# Main Installation Sequence
main() {
    # Redirect all output to log file
    exec 1> >(tee -a /var/log/skyvyos-install.log)
    exec 2>&1
    
    print_header
    
    print_info "Starting SkyvyOS Server installation..."
    print_info "Installation started at: $(date)"
    
    check_root
    check_debian
    
    # System updates
    update_system
    
    # Core packages
    install_base_packages
    install_security_packages
    install_utilities
    
    # Server software
    install_web_server
    install_docker
    install_nodejs
    install_python
    install_php
    install_certbot
    
    # Security configuration
    configure_firewall
    configure_fail2ban
    configure_ssh
    configure_automatic_updates
    apply_sysctl_hardening
    
    # Branding
    setup_branding
    create_welcome_script
    
    # Cleanup
    cleanup
    
    print_info "Installation completed at: $(date)"
    
    installation_complete
}

# Run main installation
main
