#!/bin/bash

################################################################################
# SkyvyOS Automated Incident Response System
#
# Automated incident detection and response playbooks
# Self-healing capabilities with safety limits
#
# Usage: sudo ./skyvy-incident-response.sh --daemon
################################################################################

set -euo pipefail

# Configuration
INCIDENT_LOG="/var/log/skyvyos-incidents.log"
PLAYBOOK_DIR="/etc/skyvyos/playbooks"
MAX_AUTO_ACTIONS=3  # Safety limit per incident type
ACTION_COUNTER="/var/lib/skyvyos/action_counter.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_incident() {
    local severity=$1
    local incident_type=$2
    local message=$3
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$severity] [$incident_type] $message" | tee -a "$INCIDENT_LOG"
}

send_notification() {
    local title=$1
    local message=$2
    
    # Multiple notification channels
    echo "$message" | mail -s "SkyvyOS Alert: $title" admin@localhost || true
    
    # Slack webhook (if configured)
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"$title: $message\"}" \
    #   $SLACK_WEBHOOK_URL
}

check_action_limit() {
    local incident_type=$1
    
    # Check if we've exceeded auto-action limit
    if [ -f "$ACTION_COUNTER" ]; then
        count=$(jq -r ".\"$incident_type\" // 0" "$ACTION_COUNTER")
        if [ "$count" -ge "$MAX_AUTO_ACTIONS" ]; then
            log_incident "WARN" "$incident_type" "Auto-action limit reached. Manual intervention required."
            return 1
        fi
    fi
    
    return 0
}

increment_action_counter() {
    local incident_type=$1
    
    mkdir -p "$(dirname $ACTION_COUNTER)"
    
    if [ ! -f "$ACTION_COUNTER" ]; then
        echo '{}' > "$ACTION_COUNTER"
    fi
    
    jq ".\"$incident_type\" = (.\"$incident_type\" // 0) + 1" "$ACTION_COUNTER" > "${ACTION_COUNTER}.tmp"
    mv "${ACTION_COUNTER}.tmp" "$ACTION_COUNTER"
}

# ============================================================================
# INCIDENT DETECTION & RESPONSE PLAYBOOKS
# ============================================================================

respond_high_cpu() {
    log_incident "CRITICAL" "HIGH_CPU" "CPU usage exceeded threshold"
    
    if ! check_action_limit "HIGH_CPU"; then
        return
    fi
    
    # Identify top CPU processes
    TOP_PROCS=$(ps aux --sort=-%cpu | head -n 6 | tail -n 5)
    
    log_incident "INFO" "HIGH_CPU" "Top CPU processes:\n$TOP_PROCS"
    
    # Auto-remediation: Restart problematic services
    for service in nginx docker; do
        if ps aux | grep $service | grep -v grep | awk '{if($3>50) print}' | grep -q $service; then
            log_incident "ACTION" "HIGH_CPU" "Restarting $service due to high CPU"
            systemctl restart $service
            increment_action_counter "HIGH_CPU"
            send_notification "High CPU Auto-Remediation" "Restarted $service due to high CPU usage"
        fi
    done
}

respond_high_memory() {
    log_incident "CRITICAL" "HIGH_MEMORY" "Memory usage exceeded threshold"
    
    if ! check_action_limit "HIGH_MEMORY"; then
        return
    fi
    
    # Clear page cache
    log_incident "ACTION" "HIGH_MEMORY" "Clearing page cache"
    sync; echo 1 > /proc/sys/vm/drop_caches
    
    # Kill memory hogs (with caution)
    MEM_THRESHOLD=10.0
    ps aux --sort=-%mem | awk -v thresh=$MEM_THRESHOLD '$4>thresh && $11!~/^(systemd|init|dockerd|sshd)$/ {print $2,$11}' | while read pid name; do
        log_incident "ACTION" "HIGH_MEMORY" "Killing memory hog: $name (PID: $pid)"
        kill -15 $pid || true
    done
    
    increment_action_counter "HIGH_MEMORY"
    send_notification "High Memory Auto-Remediation" "Cleared cache and killed memory hogs"
}

respond_disk_full() {
    log_incident "CRITICAL" "DISK_FULL" "Disk space exceeded threshold"
    
    if ! check_action_limit "DISK_FULL"; then
        return
    fi
    
    # Clean up old logs
    log_incident "ACTION" "DISK_FULL" "Cleaning old logs"
    journalctl --vacuum-time=7d
    find /var/log -name "*.log.*" -mtime +7 -delete
    
    # Clean Docker
    if command -v docker >/dev/null 2>&1; then
        log_incident "ACTION" "DISK_FULL" "Cleaning Docker images and containers"
        docker system prune -af --volumes
    fi
    
    # Clean APT cache
    apt-get clean
    apt-get autoclean
    
    increment_action_counter "DISK_FULL"
    send_notification "Disk Full Auto-Remediation" "Cleaned logs, Docker cache, and APT cache"
}

respond_service_down() {
    local service=$1
    
    log_incident "CRITICAL" "SERVICE_DOWN" "$service is not running"
    
    if ! check_action_limit "SERVICE_DOWN_$service"; then
        return
    fi
    
    # Attempt restart
    log_incident "ACTION" "SERVICE_DOWN" "Attempting to restart $service"
    
    if systemctl restart $service; then
        log_incident "SUCCESS" "SERVICE_DOWN" "$service restarted successfully"
        increment_action_counter "SERVICE_DOWN_$service"
        send_notification "Service Auto-Recovery" "$service was down and has been restarted"
    else
        log_incident "FAILED" "SERVICE_DOWN" "Failed to restart $service"
        send_notification "Service Recovery Failed" "$service is down and auto-restart failed. Manual intervention required."
    fi
}

respond_security_breach() {
    local breach_type=$1
    local details=$2
    
    log_incident "CRITICAL" "SECURITY_BREACH" "$breach_type: $details"
    
    # Immediate lockdown
    log_incident "ACTION" "SECURITY_BREACH" "Initiating security lockdown"
    
    # Ban suspicious IPs
    if [ "$breach_type" = "BRUTE_FORCE" ]; then
        SUSPICIOUS_IPS=$(grep "Failed password" /var/log/auth.log | tail -n 100 | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | awk '$1>5{print $2}')
        
        for ip in $SUSPICIOUS_IPS; do
            log_incident "ACTION" "SECURITY_BREACH" "Banning IP: $ip"
            fail2ban-client set sshd banip $ip
        done
    fi
    
    # Alert security team
    send_notification "🚨 SECURITY BREACH DETECTED" "$breach_type: $details\n\nAutomatic countermeasures activated. Immediate review required."
    
    # Create incident snapshot
    SNAPSHOT_DIR="/var/lib/skyvyos/incidents/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$SNAPSHOT_DIR"
    
    # Capture system state
    ps aux > "$SNAPSHOT_DIR/processes.txt"
    netstat -tulpn > "$SNAPSHOT_DIR/network.txt"
    last -20 > "$SNAPSHOT_DIR/logins.txt"
    ss -s > "$SNAPSHOT_DIR/sockets.txt"
    
    log_incident "INFO" "SECURITY_BREACH" "Incident snapshot saved to $SNAPSHOT_DIR"
}

respond_network_attack() {
    log_incident "CRITICAL" "NETWORK_ATTACK" "Potential network attack detected"
    
    # Rate limit connections
    log_incident "ACTION" "NETWORK_ATTACK" "Activating emergency rate limiting"
    
    # Update nftables with stricter rules
    nft add rule inet filter input ct count over 50 drop
    
    send_notification "Network Attack Response" "Emergency rate limiting activated"
}

# ============================================================================
# CONTINUOUS MONITORING
# ============================================================================

monitor_system() {
    while true; do
        # Check CPU
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
        if [ "$CPU_USAGE" -gt 90 ]; then
            respond_high_cpu
        fi
        
        # Check Memory
        MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", ($3/$2)*100}')
        if [ "$MEM_USAGE" -gt 90 ]; then
            respond_high_memory
        fi
        
        # Check Disk
        DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
        if [ "$DISK_USAGE" -gt 90 ]; then
            respond_disk_full
        fi
        
        # Check Critical Services
        for service in nginx docker fail2ban sshd; do
            if ! systemctl is-active --quiet $service 2>/dev/null; then
                respond_service_down $service
            fi
        done
        
        # Check for brute force attacks
        FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | grep "$(date +%b\ %d)" | wc -l)
        if [ "$FAILED_LOGINS" -gt 50 ]; then
            respond_security_breach "BRUTE_FORCE" "$FAILED_LOGINS failed login attempts today"
        fi
        
        sleep 60
    done
}

# Main
case "${1:-}" in
    --daemon)
        log_incident "INFO" "SYSTEM" "Starting automated incident response daemon"
        monitor_system
        ;;
    --reset-counters)
        rm -f "$ACTION_COUNTER"
        log_incident "INFO" "SYSTEM" "Action counters reset"
        ;;
    *)
        echo "Usage: $0 --daemon | --reset-counters"
        exit 1
        ;;
esac
