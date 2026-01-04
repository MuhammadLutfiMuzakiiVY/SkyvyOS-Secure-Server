#!/bin/bash

################################################################################
# SkyvyOS Security Audit Script
#
# Automated comprehensive security audit
# Checks CIS benchmarks, system hardening, vulnerabilities
#
# Usage: sudo ./skyvy-security-audit.sh [--report]
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Scoring
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    exit 1
fi

# Report file
REPORT_FILE="/var/log/skyvyos-security-audit-$(date +%Y%m%d-%H%M%S).log"

log_check() {
    local status=$1
    local message=$2
    local severity=${3:-INFO}
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        PASS)
            echo -e "${GREEN}[✓]${NC} $message" | tee -a "$REPORT_FILE"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        FAIL)
            echo -e "${RED}[✗]${NC} $message" | tee -a "$REPORT_FILE"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        WARN)
            echo -e "${YELLOW}[!]${NC} $message" | tee -a "$REPORT_FILE"
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
        INFO)
            echo -e "${BLUE}[i]${NC} $message" | tee -a "$REPORT_FILE"
            ;;
    esac
}

print_header() {
    echo "" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}$1${NC}" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

# Banner
clear
cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        SkyvyOS Security Audit & Compliance Scanner          ║
║              Enterprise Grade Security Assessment            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""
echo "Starting comprehensive security audit..."
echo "Report: $REPORT_FILE"
echo ""

# ============================================================================
# 1. SYSTEM CONFIGURATION
# ============================================================================
print_header "1. SYSTEM CONFIGURATION AUDIT"

# Check if SkyvyOS
if grep -q "SkyvyOS" /etc/os-release 2>/dev/null; then
    log_check "PASS" "System identified as SkyvyOS"
else
    log_check "WARN" "System is not identified as SkyvyOS"
fi

# Check kernel version
KERNEL_VERSION=$(uname -r)
log_check "INFO" "Kernel version: $KERNEL_VERSION"

# ============================================================================
# 2. SSH HARDENING
# ============================================================================
print_header "2. SSH SECURITY CONFIGURATION"

# SSH password authentication
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    log_check "PASS" "SSH password authentication is disabled"
else
    log_check "FAIL" "SSH password authentication is ENABLED (security risk)"
fi

# Root login
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    log_check "PASS" "SSH root login is disabled"
else
    log_check "FAIL" "SSH root login is ENABLED (security risk)"
fi

# SSH protocol
if grep -q "^Protocol 2" /etc/ssh/sshd_config 2>/dev/null; then
    log_check "PASS" "SSH Protocol 2 enforced"
else
    log_check "WARN" "SSH Protocol not explicitly set (should be 2 only)"
fi

# ============================================================================
# 3. FIREWALL CONFIGURATION
# ============================================================================
print_header "3. FIREWALL & NETWORK SECURITY"

# Check nftables/ufw
if systemctl is-active --quiet nftables; then
    log_check "PASS" "nftables firewall is active"
elif systemctl is-active --quiet ufw; then
    log_check "PASS" "UFW firewall is active"
else
    log_check "FAIL" "No firewall is active (CRITICAL RISK)"
fi

# Check IP forwarding (should be disabled unless routing)
if sysctl net.ipv4.ip_forward | grep -q "= 0"; then
    log_check "PASS" "IP forwarding is disabled"
else
    log_check "WARN" "IP forwarding is enabled (check if needed)"
fi

# SYN cookies
if sysctl net.ipv4.tcp_syncookies | grep -q "= 1"; then
    log_check "PASS" "SYN cookies enabled (DDoS protection)"
else
    log_check "FAIL" "SYN cookies disabled (vulnerable to SYN flood)"
fi

# ============================================================================
# 4. INTRUSION DETECTION
# ============================================================================
print_header "4. INTRUSION DETECTION & PREVENTION"

# Fail2Ban
if systemctl is-active --quiet fail2ban; then
    log_check "PASS" "Fail2Ban is active"
    
    # Check banned IPs
    BANNED_COUNT=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "0")
    log_check "INFO" "Currently banned IPs: $BANNED_COUNT"
else
    log_check "FAIL" "Fail2Ban is not active (no brute-force protection)"
fi

# Auditd
if systemctl is-active --quiet auditd; then
    log_check "PASS" "Auditd is active (forensic logging enabled)"
else
    log_check "WARN" "Auditd is not active (limited forensic capability)"
fi

# AIDE
if command -v aide >/dev/null 2>&1; then
    log_check "PASS" "AIDE installed (file integrity monitoring)"
    
    if [ -f /var/lib/aide/aide.db ]; then
        log_check "PASS" "AIDE database initialized"
    else
        log_check "WARN" "AIDE database not initialized (run: aideinit)"
    fi
else
    log_check "WARN" "AIDE not installed (no file integrity monitoring)"
fi

# ============================================================================
# 5. USER & ACCESS CONTROL
# ============================================================================
print_header "5. USER & ACCESS CONTROL"

# Check for users with UID 0 (should only be root)
UID0_USERS=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
if [ "$UID0_USERS" == "root" ]; then
    log_check "PASS" "Only root has UID 0"
else
    log_check "FAIL" "Multiple users with UID 0: $UID0_USERS"
fi

# Check for empty passwords
EMPTY_PASS=$(awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null || echo "")
if [ -z "$EMPTY_PASS" ]; then
    log_check "PASS" "No users with empty passwords"
else
    log_check "FAIL" "Users with empty passwords: $EMPTY_PASS"
fi

# Sudo configuration
if [ -f /etc/sudoers.d/skyvyos-policy ]; then
    log_check "PASS" "SkyvyOS sudo policy installed"
else
    log_check "WARN" "SkyvyOS sudo policy not found"
fi

# ============================================================================
# 6. KERNEL HARDENING
# ============================================================================
print_header "6. KERNEL & SYSTEM HARDENING"

# Check sysctl hardening
HARDENING_FILE="/etc/sysctl.d/99-skyvyos-hardening.conf"
if [ -f "$HARDENING_FILE" ]; then
    log_check "PASS" "Kernel hardening configuration exists"
else
    log_check "WARN" "Kernel hardening configuration not found"
fi

# AppArmor
if systemctl is-active --quiet apparmor 2>/dev/null; then
    log_check "PASS" "AppArmor is active (mandatory access control)"
else
    log_check "WARN" "AppArmor is not active (reduced container security)"
fi

# ============================================================================
# 7. FILESYSTEM SECURITY
# ============================================================================
print_header "7. FILESYSTEM SECURITY"

# Check /tmp mount options
if mount | grep " /tmp " | grep -q "noexec"; then
    log_check "PASS" "/tmp mounted with noexec"
else
    log_check "WARN" "/tmp not mounted with noexec (executables can run from /tmp)"
fi

# Check world-writable files
WORLD_WRITABLE=$(find / -xdev -type f -perm -0002 2>/dev/null | wc -l)
if [ "$WORLD_WRITABLE" -eq 0 ]; then
    log_check "PASS" "No world-writable files found"
else
    log_check "WARN" "$WORLD_WRITABLE world-writable files found (investigate)"
fi

# ============================================================================
# 8. SERVICES & DAEMONS
# ============================================================================
print_header "8. RUNNING SERVICES AUDIT"

# Count running services
RUNNING_SERVICES=$(systemctl list-units --type=service --state=running | grep -c "\.service" || echo "0")
log_check "INFO" "Running services: $RUNNING_SERVICES"

# Check for unnecessary services
UNNECESSARY=(
    "telnet"
    "rsh"
    "rlogin"
    "vsftpd"
    "pure-ftpd"
)

for service in "${UNNECESSARY[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log_check "FAIL" "Insecure service running: $service"
    fi
done

# ============================================================================
# 9. PACKAGE MANAGEMENT
# ============================================================================
print_header "9. PACKAGE & UPDATE SECURITY"

# Check for available updates
if command -v apt >/dev/null 2>&1; then
    apt update -qq 2>/dev/null
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    
    if [ "$UPDATES" -eq 0 ]; then
        log_check "PASS" "System is up to date"
    else
        log_check "WARN" "$UPDATES updates available (apply soon)"
    fi
fi

# Unattended upgrades
if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
    log_check "PASS" "Automatic security updates enabled"
else
    log_check "WARN" "Automatic security updates not configured"
fi

# ============================================================================
# 10. VULNERABILITY SCAN
# ============================================================================
print_header "10. VULNERABILITY SCANNING"

# Check if Lynis is available
if command -v lynis >/dev/null 2>&1; then
    log_check "PASS" "Lynis security scanner installed"
    echo "Running Lynis quick scan..." | tee -a "$REPORT_FILE"
    lynis audit system --quick --quiet >> "$REPORT_FILE" 2>&1 || true
else
    log_check "WARN" "Lynis not installed (install for detailed scanning)"
fi

# ============================================================================
# FINAL REPORT
# ============================================================================
print_header "SECURITY AUDIT SUMMARY"

SECURITY_SCORE=$(echo "scale=1; ($PASSED_CHECKS * 100) / $TOTAL_CHECKS" | bc)

echo "" | tee -a "$REPORT_FILE"
echo "Total Checks   : $TOTAL_CHECKS" | tee -a "$REPORT_FILE"
echo -e "${GREEN}Passed         : $PASSED_CHECKS${NC}" | tee -a "$REPORT_FILE"
echo -e "${RED}Failed         : $FAILED_CHECKS${NC}" | tee -a "$REPORT_FILE"
echo -e "${YELLOW}Warnings       : $WARNING_CHECKS${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo -e "Security Score : ${CYAN}$SECURITY_SCORE%${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Grade
if (( $(echo "$SECURITY_SCORE >= 90" | bc -l) )); then
    echo -e "Security Grade : ${GREEN}A (Excellent)${NC}" | tee -a "$REPORT_FILE"
elif (( $(echo "$SECURITY_SCORE >= 80" | bc -l) )); then
    echo -e "Security Grade : ${CYAN}B (Good)${NC}" | tee -a "$REPORT_FILE"
elif (( $(echo "$SECURITY_SCORE >= 70" | bc -l) )); then
    echo -e "Security Grade : ${YELLOW}C (Fair)${NC}" | tee -a "$REPORT_FILE"
else
    echo -e "Security Grade : ${RED}D (Poor - Action Required)${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "Full report saved: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Recommendations
if [ "$FAILED_CHECKS" -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL: $FAILED_CHECKS security issues detected!${NC}" | tee -a "$REPORT_FILE"
    echo "Review the report and fix critical issues immediately." | tee -a "$REPORT_FILE"
fi

exit 0
