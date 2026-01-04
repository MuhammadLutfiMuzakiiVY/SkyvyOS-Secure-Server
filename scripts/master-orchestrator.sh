#!/bin/bash

################################################################################
# SkyvyOS Master Orchestrator - Complete System Installation
#
# One script to rule them all - Complete SkyvyOS installation & hardening
# This script orchestrates all installation and hardening scripts in order
#
# Usage: sudo ./master-orchestrator.sh [options]
# Options:
#   --minimal          : Base install only (no languages)
#   --polyglot         : Include all programming languages
#   --full             : Everything (default)
#   --skip-hardening   : Skip security hardening
#
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     ███████╗██╗  ██╗██╗   ██╗██╗   ██╗██╗   ██╗         ║
║     ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║   ██║╚██╗ ██╔╝         ║
║     ███████╗█████╔╝  ╚████╔╝ ██║   ██║ ╚████╔╝          ║
║     ╚════██║██╔═██╗   ╚██╔╝  ╚██╗ ██╔╝  ╚██╔╝           ║
║     ███████║██║  ██╗   ██║    ╚████╔╝    ██║            ║
║     ╚══════╝╚═╝  ╚═╝   ╚═╝     ╚═══╝     ╚═╝            ║
║                                                           ║
║              MASTER ORCHESTRATOR                          ║
║        Enterprise Security-Hardened Server OS             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}Complete System Installation & Hardening${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

# Parse arguments
MODE="full"
SKIP_HARDENING=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            MODE="minimal"
            shift
            ;;
        --polyglot)
            MODE="polyglot"
            shift
            ;;
        --full)
            MODE="full"
            shift
            ;;
        --skip-hardening)
            SKIP_HARDENING=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/skyvyos-install-$(date +%Y%m%d-%H%M%S).log"
START_TIME=$(date +%s)

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_step() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${GREEN}════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Start logging
log_info "SkyvyOS Master Orchestrator"
log_info "Mode: $MODE"
log_info "Log file: $LOG_FILE"
log_info "Started at: $(date)"

# ============================================================================
# PHASE 1: Pre-flight Checks
# ============================================================================
log_step "PHASE 1: Pre-flight Checks"

log_info "Checking system requirements..."

# Check Debian version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "debian" ]; then
        log_error "This script is designed for Debian. Detected: $ID"
        exit 1
    fi
    log_info "OS: $PRETTY_NAME"
else
    log_error "Cannot determine OS version"
    exit 1
fi

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    log_error "No internet connection. Installation requires network access."
    exit 1
fi
log_info "Internet connection: OK"

# Check disk space (minimum 5GB free)
FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 5242880 ]; then
    log_warning "Low disk space: $(($FREE_SPACE / 1024 / 1024))GB available"
fi

log_info "Pre-flight checks complete"

# ============================================================================
# PHASE 2: System Update
# ============================================================================
log_step "PHASE 2: System Update & Base Packages"

log_info "Updating package lists..."
apt-get update >> "$LOG_FILE" 2>&1

log_info "Upgrading existing packages..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1

log_info "Installing base dependencies..."
apt-get install -y \
    curl wget git \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common >> "$LOG_FILE" 2>&1

# ============================================================================
# PHASE 3: SkyvyOS Base Installation
# ============================================================================
log_step "PHASE 3: SkyvyOS Base Installation"

if [ -f "$SCRIPT_DIR/install-skyvyos.sh" ]; then
    log_info "Running install-skyvyos.sh..."
    bash "$SCRIPT_DIR/install-skyvyos.sh" >> "$LOG_FILE" 2>&1
else
    log_warning "install-skyvyos.sh not found, skipping..."
fi

# ============================================================================
# PHASE 4: Security Hardening
# ============================================================================
if [ "$SKIP_HARDENING" = false ]; then
    log_step "PHASE 4: Security Hardening"
    
    if [ -f "$SCRIPT_DIR/security-hardening.sh" ]; then
        log_info "Running security-hardening.sh..."
        bash "$SCRIPT_DIR/security-hardening.sh" >> "$LOG_FILE" 2>&1
    else
        log_warning "security-hardening.sh not found, skipping..."
    fi
    
    # Apply nftables firewall
    if [ -f "$SCRIPT_DIR/../config/nftables.conf" ]; then
        log_info "Configuring nftables firewall..."
        cp "$SCRIPT_DIR/../config/nftables.conf" /etc/nftables.conf
        systemctl enable nftables
        systemctl start nftables
        log_info "nftables firewall active"
    fi
else
    log_warning "Skipping security hardening (--skip-hardening flag)"
fi

# ============================================================================
# PHASE 5: Programming Languages (Polyglot)
# ============================================================================
if [ "$MODE" = "polyglot" ] || [ "$MODE" = "full" ]; then
    log_step "PHASE 5: Programming Languages Installation"
    
    if [ -f "$SCRIPT_DIR/install-polyglot-languages.sh" ]; then
        log_info "Running install-polyglot-languages.sh..."
        bash "$SCRIPT_DIR/install-polyglot-languages.sh" >> "$LOG_FILE" 2>&1
    else
        log_warning "install-polyglot-languages.sh not found, skipping..."
    fi
else
    log_info "Skipping programming languages installation (minimal mode)"
fi

# ============================================================================
# PHASE 6: Additional Configuration
# ============================================================================
log_step "PHASE 6: Additional Configuration"

# Configure automatic security updates
log_info "Configuring automatic security updates..."
apt-get install -y unattended-upgrades >> "$LOG_FILE" 2>&1
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Enable services
log_info "Enabling essential services..."
systemctl enable ssh
systemctl enable fail2ban
systemctl enable auditd
systemctl enable nftables

# ============================================================================
# PHASE 7: Branding & Final Touches
# ============================================================================
log_step "PHASE 7: Branding & Final Touches"

# Copy branding files
if [ -d "$SCRIPT_DIR/../branding" ]; then
    log_info "Applying SkyvyOS branding..."
    [ -f "$SCRIPT_DIR/../branding/os-release" ] && cp "$SCRIPT_DIR/../branding/os-release" /etc/os-release
    [ -f "$SCRIPT_DIR/../branding/motd" ] && cp "$SCRIPT_DIR/../branding/motd" /etc/motd
    [ -f "$SCRIPT_DIR/../branding/issue" ] && cp "$SCRIPT_DIR/../branding/issue" /etc/issue
    [ -f "$SCRIPT_DIR/../branding/skyvy-info.sh" ] && cp "$SCRIPT_DIR/../branding/skyvy-info.sh" /usr/local/bin/skyvy-info && chmod +x /usr/local/bin/skyvy-info
fi

# Create system info command
log_info "Creating system utilities..."
cat > /usr/local/bin/skyvyos-info <<'EOFINFO'
#!/bin/bash
echo "SkyvyOS Secure Server"
echo "====================="
echo ""
echo "Version: $(cat /etc/os-release | grep VERSION= | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""
echo "Installed Components:"
[ -x /usr/bin/python3 ] && echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
[ -x /usr/bin/node ] && echo "  ✓ Node.js $(node --version)"
[ -x /usr/bin/php ] && echo "  ✓ PHP $(php -v | head -n1 | cut -d' ' -f2)"
[ -x /usr/sbin/nginx ] && echo "  ✓ Nginx $(nginx -v 2>&1 | cut -d'/' -f2)"
[ -x /usr/bin/docker ] && echo "  ✓ Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo ""
echo "Security Status:"
systemctl is-active fail2ban >/dev/null && echo "  ✓ Fail2Ban: Active" || echo "  ✗ Fail2Ban: Inactive"
systemctl is-active auditd >/dev/null && echo "  ✓ Auditd: Active" || echo "  ✗ Auditd: Inactive"
systemctl is-active nftables >/dev/null && echo "  ✓ nftables: Active" || echo "  ✗ nftables: Inactive"
echo ""
EOFINFO
chmod +x /usr/local/bin/skyvyos-info

# Cleanup
log_info "Cleaning up..."
apt-get autoremove -y >> "$LOG_FILE" 2>&1
apt-get autoclean >> "$LOG_FILE" 2>&1

# ============================================================================
# COMPLETION
# ============================================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║        SkyvyOS INSTALLATION COMPLETE!                     ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Installation Summary:${NC}"
echo "  Mode: $MODE"
echo "  Duration: $((DURATION / 60)) minutes $((DURATION % 60)) seconds"
echo "  Log file: $LOG_FILE"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Add your SSH public key to ~/.ssh/authorized_keys"
echo "  2. Review firewall rules: nft list ruleset"
echo "  3. Check system status: skyvyos-info"
echo "  4. Reboot the system: reboot"
echo ""
echo -e "${YELLOW}Important Security Notes:${NC}"
echo "  • SSH password authentication is DISABLED"
echo "  • Only SSH key authentication is allowed"
echo "  • Root login via SSH is DISABLED"
echo "  • Ensure you have SSH key access before rebooting!"
echo ""
echo -e "${BLUE}View this information anytime: skyvyos-info${NC}"
echo ""
echo -e "${GREEN}SkyvyOS Secure Server is ready for production! 🚀${NC}"
echo ""

# Final check prompt
echo -e "${YELLOW}Do you want to reboot now? (y/N)${NC}"
read -r REBOOT_CHOICE
if [ "$REBOOT_CHOICE" = "y" ] || [ "$REBOOT_CHOICE" = "Y" ]; then
    log_info "Rebooting system..."
    reboot
else
    log_info "Installation complete. Reboot manually when ready."
fi
