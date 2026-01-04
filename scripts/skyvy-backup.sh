#!/bin/bash

################################################################################
# SkyvyOS Automated Backup System
#
# Automated backup for critical system files and configurations
# Uses rsync for incremental backups
#
# Usage: sudo ./skyvy-backup.sh [--schedule]
################################################################################

set -euo pipefail

# Configuration
BACKUP_ROOT="/var/backups/skyvyos"
RETENTION_DAYS=30
BACKUP_LOG="/var/log/skyvyos-backup.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/backup-$TIMESTAMP"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$BACKUP_LOG"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting SkyvyOS backup to $BACKUP_DIR"

# Critical directories to backup
BACKUP_PATHS=(
    "/etc"
    "/root"
    "/home"
    "/var/www"
    "/usr/local/bin"
    "/var/spool/cron"
)

# Backup each path
for path in "${BACKUP_PATHS[@]}"; do
    if [ -d "$path" ]; then
        log "Backing up $path..."
        rsync -a --delete "$path" "$BACKUP_DIR/" 2>&1 | tee -a "$BACKUP_LOG"
    fi
done

# Backup package list
log "Backing up package list..."
dpkg --get-selections > "$BACKUP_DIR/package-selections.txt"
apt-mark showauto > "$BACKUP_DIR/apt-auto-packages.txt"

# Backup firewall rules
log "Backing up firewall rules..."
if command -v nft >/dev/null 2>&1; then
    nft list ruleset > "$BACKUP_DIR/nftables-rules.nft"
fi

# Create manifest
log "Creating backup manifest..."
cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
SkyvyOS Backup Manifest
=======================
Date: $(date)
Hostname: $(hostname)
Kernel: $(uname -r)
Backup Size: $(du -sh $BACKUP_DIR | cut -f1)

Backed up paths:
$(for p in "${BACKUP_PATHS[@]}"; do echo "  - $p"; done)

Package count: $(wc -l < $BACKUP_DIR/package-selections.txt)
EOF

# Cleanup old backups
log "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_ROOT" -maxdepth 1 -name "backup-*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true

# Create latest symlink
ln -sfn "$BACKUP_DIR" "$BACKUP_ROOT/latest"

log "Backup completed successfully"
echo -e "${GREEN}✓${NC} Backup saved to: $BACKUP_DIR"
echo -e "${GREEN}✓${NC} Backup size: $(du -sh $BACKUP_DIR | cut -f1)"

# If --schedule flag, setup cron
if [ "${1:-}" = "--schedule" ]; then
    log "Setting up automatic daily backup..."
    
    # Add to cron
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/skyvy-backup.sh >> $BACKUP_LOG 2>&1") | crontab -
    
    echo -e "${GREEN}✓${NC} Automatic daily backup scheduled (2 AM)"
fi
