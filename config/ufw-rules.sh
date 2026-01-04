#!/bin/bash

################################################################################
# SkyvyOS UFW Firewall Default Rules
# This script configures the default firewall rules for SkyvyOS Server
################################################################################

echo "Configuring UFW firewall rules..."

# Reset to defaults
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Enable logging
ufw logging on

# Allow SSH (port 22)
ufw allow 22/tcp comment 'SSH'

# Allow HTTP (port 80)
ufw allow 80/tcp comment 'HTTP'

# Allow HTTPS (port 443)
ufw allow 443/tcp comment 'HTTPS'

# Optional: Allow custom application ports
# Uncomment and modify as needed:
# ufw allow 3000/tcp comment 'Node.js App'
# ufw allow 8080/tcp comment 'Alternative HTTP'
# ufw allow 5432/tcp comment 'PostgreSQL'
# ufw allow 3306/tcp comment 'MySQL/MariaDB'
# ufw allow 6379/tcp comment 'Redis'
# ufw allow 27017/tcp comment 'MongoDB'

# Optional: Allow from specific IP/subnet
# ufw allow from 192.168.1.0/24

# Optional: Limit SSH connections (rate limiting)
# ufw limit 22/tcp

# Enable UFW
ufw --force enable

echo "✓ Firewall configured successfully"
echo ""
echo "Current firewall status:"
ufw status verbose
