#!/bin/bash

################################################################################
# SkyvyOS System Information Display
# 
# Beautiful, colorful system information display
# Shows critical system stats at login
################################################################################

# Colors
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Foreground colors
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# Bright colors
BRIGHT_BLACK='\033[90m'
BRIGHT_RED='\033[91m'
BRIGHT_GREEN='\033[92m'
BRIGHT_YELLOW='\033[93m'
BRIGHT_BLUE='\033[94m'
BRIGHT_MAGENTA='\033[95m'
BRIGHT_CYAN='\033[96m'
BRIGHT_WHITE='\033[97m'

# Background colors
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'

# Box drawing
BOX_H="═"
BOX_V="║"
BOX_TL="╔"
BOX_TR="╗"
BOX_BL="╚"
BOX_BR="╝"

# Functions
print_header() {
    local width=76
    echo -e "${CYAN}${BOX_TL}$(printf '%*s' $width | tr ' ' $BOX_H)${BOX_TR}${RESET}"
    printf "${CYAN}${BOX_V}${RESET}${BOLD}${BRIGHT_CYAN}%*s${RESET}${CYAN}${BOX_V}${RESET}\n" $((($width + ${#1}) / 2)) "$1"
    echo -e "${CYAN}${BOX_BL}$(printf '%*s' $width | tr ' ' $BOX_H)${BOX_BR}${RESET}"
}

print_section() {
    echo ""
    echo -e "${BOLD}${BRIGHT_YELLOW}▶ $1${RESET}"
    echo -e "${DIM}${BRIGHT_BLACK}$(printf '%.0s─' {1..76})${RESET}"
}

print_item() {
    local label="$1"
    local value="$2"
    local color="${3:-$BRIGHT_WHITE}"
    printf "  ${BRIGHT_BLACK}•${RESET} ${BOLD}%-20s${RESET} : ${color}%s${RESET}\n" "$label" "$value"
}

get_uptime() {
    uptime -p | sed 's/up //'
}

get_load() {
    cat /proc/loadavg | awk '{print $1" "$2" "$3}'
}

get_memory() {
    free -h | awk 'NR==2{printf "%s / %s (%.1f%%)", $3, $2, ($3/$2)*100}'
}

get_disk() {
    df -h / | awk 'NR==2{printf "%s / %s (%.1f%%)", $3, $2, ($3/$2)*100}'
}

get_processes() {
    ps aux | wc -l
}

get_logged_users() {
    who | wc -l
}

get_public_ip() {
    timeout 2 curl -s ifconfig.me 2>/dev/null || echo "N/A"
}

get_local_ip() {
    hostname -I | awk '{print $1}'
}

# Clear screen for clean display
clear

# Header
print_header "SkyvyOS System Information"

# OS Information Section
print_section "📋 SYSTEM INFORMATION"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_item "Operating System" "$PRETTY_NAME" "$BRIGHT_CYAN"
    print_item "Version" "${VERSION:-N/A}" "$CYAN"
fi
print_item "Kernel" "$(uname -r)" "$BRIGHT_BLUE"
print_item "Architecture" "$(uname -m)" "$BLUE"
print_item "Hostname" "$(hostname)" "$BRIGHT_MAGENTA"

# Performance Section
print_section "⚡ PERFORMANCE"
print_item "Uptime" "$(get_uptime)" "$BRIGHT_GREEN"
print_item "Load Average" "$(get_load)" "$YELLOW"
print_item "Processes" "$(get_processes)" "$BRIGHT_YELLOW"
print_item "Logged Users" "$(get_logged_users)" "$CYAN"

# Resources Section
print_section "💾 RESOURCES"
print_item "Memory Usage" "$(get_memory)" "$BRIGHT_GREEN"
print_item "Disk Usage (/)" "$(get_disk)" "$BRIGHT_BLUE"
print_item "CPU Cores" "$(nproc)" "$MAGENTA"

# Network Section
print_section "🌐 NETWORK"
print_item "Local IP" "$(get_local_ip)" "$BRIGHT_CYAN"
print_item "Public IP" "$(get_public_ip)" "$CYAN"

# Services Section
print_section "🔧 CRITICAL SERVICES"

check_service() {
    local service=$1
    local display_name=$2
    if systemctl is-active --quiet $service; then
        print_item "$display_name" "✓ Running" "$BRIGHT_GREEN"
    else
        print_item "$display_name" "✗ Stopped" "$BRIGHT_RED"
    fi
}

check_service "nginx" "Web Server (Nginx)"
check_service "docker" "Docker Engine"
check_service "fail2ban" "Fail2Ban IPS"
check_service "ssh" "SSH Server"
check_service "nftables" "nftables Firewall"
check_service "auditd" "Audit Daemon"

# Security Section
print_section "🛡️  SECURITY STATUS"

# Check firewall
if systemctl is-active --quiet nftables || systemctl is-active --quiet ufw; then
    print_item "Firewall" "✓ Active" "$BRIGHT_GREEN"
else
    print_item "Firewall" "✗ Inactive" "$BRIGHT_RED"
fi

# Check fail2ban
if systemctl is-active --quiet fail2ban; then
    BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    print_item "Intrusion Prevention" "✓ Active (${BANNED_IPS:-0} IPs banned)" "$BRIGHT_GREEN"
else
    print_item "Intrusion Prevention" "✗ Inactive" "$BRIGHT_RED"
fi

# Check updates
if command -v apt >/dev/null 2>&1; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    if [ "$UPDATES" -gt 0 ]; then
        print_item "System Updates" "$UPDATES available" "$BRIGHT_YELLOW"
    else
        print_item "System Updates" "✓ Up to date" "$BRIGHT_GREEN"
    fi
fi

# Programming Languages Section
print_section "💻 PROGRAMMING LANGUAGES"

lang_check() {
    local cmd=$1
    local name=$2
    local version_flag=${3:---version}
    
    if command -v $cmd >/dev/null 2>&1; then
        local version=$($cmd $version_flag 2>&1 | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' | head -n1)
        print_item "$name" "✓ v${version:-installed}" "$BRIGHT_CYAN"
    fi
}

lang_check "python3" "Python"
lang_check "node" "Node.js" "--version"
lang_check "php" "PHP" "--version"
lang_check "go" "Go" "version"
lang_check "rustc" "Rust" "--version"
lang_check "ruby" "Ruby" "--version"
lang_check "java" "Java" "--version"

# Footer
echo ""
echo -e "${DIM}${BRIGHT_BLACK}$(printf '%.0s─' {1..76})${RESET}"
echo ""
echo -e "  ${BRIGHT_CYAN}📚 Documentation${RESET}    : ${BRIGHT_WHITE}https://github.com/MuhammadLutfiMuzakiYY/SkyvyOS-Secure-Server${RESET}"
echo -e "  ${BRIGHT_GREEN}🔍 System Info${RESET}       : ${BRIGHT_WHITE}skyvyos-info${RESET}"
echo -e "  ${BRIGHT_YELLOW}🔒 Security Audit${RESET}    : ${BRIGHT_WHITE}sudo skyvy-security-audit${RESET}"
echo ""
echo -e "${DIM}${BRIGHT_BLACK}$(printf '%.0s─' {1..76})${RESET}"
echo ""
echo -e "  ${BOLD}${BRIGHT_GREEN}SkyvyOS Secure Server${RESET} ${DIM}- Enterprise Security-Hardened Linux${RESET}"
echo ""
