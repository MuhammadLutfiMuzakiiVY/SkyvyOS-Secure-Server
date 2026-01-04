#!/bin/bash

################################################################################
# SkyvyOS Health Monitor
#
# Real-time system health monitoring with alerting
# Monitors CPU, memory, disk, services, security
#
# Usage: 
#   sudo ./skyvy-health-monitor.sh        # One-time check
#   sudo ./skyvy-health-monitor.sh --watch   # Continuous monitoring
#   sudo ./skyvy-health-monitor.sh --daemon  # Run as background daemon
################################################################################

set -euo pipefail

# Configuration
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
LOAD_THRESHOLD=4.0
ALERT_EMAIL="admin@localhost"
HEALTH_LOG="/var/log/skyvyos-health.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Status tracking
CRITICAL_ISSUES=0
WARNING_ISSUES=0
HEALTHY_CHECKS=0

log_health() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG"
}

alert() {
    local severity=$1
    local message=$2
    
    log_health "[$severity] $message"
    
    # Send email alert (if mail is configured)
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "SkyvyOS Health Alert: $severity" "$ALERT_EMAIL"
    fi
}

check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local cpu_int=${cpu_usage%.*}
    
    if [ "$cpu_int" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}[✗]${NC} CPU Usage: ${RED}${cpu_usage}%${NC} (Critical)"
        alert "CRITICAL" "CPU usage is ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    elif [ "$cpu_int" -gt 60 ]; then
        echo -e "${YELLOW}[!]${NC} CPU Usage: ${YELLOW}${cpu_usage}%${NC} (Warning)"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    else
        echo -e "${GREEN}[✓]${NC} CPU Usage: ${GREEN}${cpu_usage}%${NC} (Healthy)"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    fi
}

check_memory() {
    local mem_info=$(free | awk 'NR==2{printf "%.0f", ($3/$2)*100}')
    
    if [ "$mem_info" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}[✗]${NC} Memory Usage: ${RED}${mem_info}%${NC} (Critical)"
        alert "CRITICAL" "Memory usage is ${mem_info}% (threshold: ${MEMORY_THRESHOLD}%)"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    elif [ "$mem_info" -gt 70 ]; then
        echo -e "${YELLOW}[!]${NC} Memory Usage: ${YELLOW}${mem_info}%${NC} (Warning)"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    else
        echo -e "${GREEN}[✓]${NC} Memory Usage: ${GREEN}${mem_info}%${NC} (Healthy)"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    fi
}

check_disk() {
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${RED}[✗]${NC} Disk Usage: ${RED}${disk_usage}%${NC} (Critical)"
        alert "CRITICAL" "Disk usage is ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    elif [ "$disk_usage" -gt 75 ]; then
        echo -e "${YELLOW}[!]${NC} Disk Usage: ${YELLOW}${disk_usage}%${NC} (Warning)"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    else
        echo -e "${GREEN}[✓]${NC} Disk Usage: ${GREEN}${disk_usage}%${NC} (Healthy)"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    fi
}

check_load() {
    local load_avg=$(cat /proc/loadavg | awk '{print $1}')
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc)
    
    if (( $(echo "$load_per_core > 1.0" | bc -l) )); then
        echo -e "${YELLOW}[!]${NC} Load Average: ${YELLOW}${load_avg}${NC} (High)"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    else
        echo -e "${GREEN}[✓]${NC} Load Average: ${GREEN}${load_avg}${NC} (Normal)"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    fi
}

check_services() {
    local critical_services=(
        "sshd"
        "nginx"
        "docker"
        "fail2ban"
        "nftables:ufw"  # Either nftables or ufw
    )
    
    for service_spec in "${critical_services[@]}"; do
        # Handle alternative services (nftables:ufw)
        IFS=':' read -ra services <<< "$service_spec"
        
        local running=false
        local service_name=""
        
        for service in "${services[@]}"; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                running=true
                service_name="$service"
                break
            fi
        done
        
        if [ "$running" = true ]; then
            echo -e "${GREEN}[✓]${NC} Service ${service_name}: ${GREEN}Running${NC}"
            HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
        else
            echo -e "${RED}[✗]${NC} Service ${services[0]}: ${RED}Stopped${NC} (Critical)"
            alert "CRITICAL" "Critical service ${services[0]} is not running"
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
        fi
    done
}

check_security() {
    # Check firewall
    if systemctl is-active --quiet nftables || systemctl is-active --quiet ufw; then
        echo -e "${GREEN}[✓]${NC} Firewall: ${GREEN}Active${NC}"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    else
        echo -e "${RED}[✗]${NC} Firewall: ${RED}Inactive${NC} (Critical)"
        alert "CRITICAL" "Firewall is not active"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    fi
    
    # Check Fail2Ban ban count
    if systemctl is-active --quiet fail2ban; then
        local banned=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "0")
        if [ "$banned" -gt 10 ]; then
            echo -e "${YELLOW}[!]${NC} Fail2Ban: ${YELLOW}${banned} IPs banned${NC} (High activity)"
            WARNING_ISSUES=$((WARNING_ISSUES + 1))
        else
            echo -e "${GREEN}[✓]${NC} Fail2Ban: ${GREEN}${banned} IPs banned${NC}"
            HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
        fi
    fi
}

check_network() {
    # Check internet connectivity
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}[✓]${NC} Internet: ${GREEN}Connected${NC}"
        HEALTHY_CHECKS=$((HEALTHY_CHECKS + 1))
    else
        echo -e "${RED}[✗]${NC} Internet: ${RED}Disconnected${NC}"
        alert "WARNING" "No internet connectivity"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    fi
}

run_health_check() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        SkyvyOS Health Monitor - $(date '+%Y-%m-%d %H:%M:%S')        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Reset counters
    CRITICAL_ISSUES=0
    WARNING_ISSUES=0
    HEALTHY_CHECKS=0
    
    echo -e "${BOLD}${CYAN}SYSTEM RESOURCES${NC}"
    echo "────────────────────────────────────────────────────────────────"
    check_cpu
    check_memory
    check_disk
    check_load
    
    echo ""
    echo -e "${BOLD}${CYAN}CRITICAL SERVICES${NC}"
    echo "────────────────────────────────────────────────────────────────"
    check_services
    
    echo ""
    echo -e "${BOLD}${CYAN}SECURITY STATUS${NC}"
    echo "────────────────────────────────────────────────────────────────"
    check_security
    
    echo ""
    echo -e "${BOLD}${CYAN}NETWORK${NC}"
    echo "────────────────────────────────────────────────────────────────"
    check_network
    
    # Summary
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${GREEN}Healthy Checks  : $HEALTHY_CHECKS${NC}"
    echo -e "${YELLOW}Warnings        : $WARNING_ISSUES${NC}"
    echo -e "${RED}Critical Issues : $CRITICAL_ISSUES${NC}"
    echo "════════════════════════════════════════════════════════════════"
    
    # Overall status
    if [ "$CRITICAL_ISSUES" -eq 0 ] && [ "$WARNING_ISSUES" -eq 0 ]; then
        echo -e "${GREEN}Overall Status  : HEALTHY ✓${NC}"
    elif [ "$CRITICAL_ISSUES" -eq 0 ]; then
        echo -e "${YELLOW}Overall Status  : DEGRADED !${NC}"
    else
        echo -e "${RED}Overall Status  : CRITICAL ✗${NC}"
    fi
    echo ""
    
    log_health "Health check completed: Healthy=$HEALTHY_CHECKS, Warnings=$WARNING_ISSUES, Critical=$CRITICAL_ISSUES"
}

# Main
case "${1:-}" in
    --watch)
        while true; do
            run_health_check
            sleep 60
        done
        ;;
    --daemon)
        echo "Starting health monitor daemon..."
        while true; do
            run_health_check >/dev/null 2>&1
            sleep 300  # Check every 5 minutes
        done &
        echo "Health monitor running in background (PID: $!)"
        ;;
    *)
        run_health_check
        ;;
esac
