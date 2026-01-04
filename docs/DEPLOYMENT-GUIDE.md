# SkyvyOS Server - Deployment Guide

Complete guide for deploying and configuring SkyvyOS Server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Initial Setup](#initial-setup)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Service Configuration](#service-configuration)
6. [Security Setup](#security-setup)
7. [Application Deployment](#application-deployment)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements

- **CPU**: 1 core minimum (2+ recommended)
- **RAM**: 512 MB minimum (1 GB+ recommended for Docker)
- **Disk**: 5 GB minimum (10 GB+ recommended)
- **Network**: Internet connection required for installation

### Software Requirements

- **Base OS**: Debian 12 (Bookworm) minimal installation
- **Access**: Root or sudo access
- **SSH**: Terminal access to the server

## Installation Methods

### Method 1: From Debian Netinst (Recommended)

1. **Download Debian 12 Netinst ISO**
   ```
   https://www.debian.org/CD/netinst/
   ```

2. **Install Debian Minimal**
   - Boot from ISO
   - Choose "Install" (not graphical install)
   - Select language, location, keyboard
   - Configure network
   - Set hostname (will be changed to SkyvyOS later)
   - Create root password
   - Create user account
   - Partition disk (use entire disk, single partition)
   - **Important**: When selecting software, **uncheck everything** except "SSH server" and "standard system utilities"
   - Complete installation and reboot

3. **Download SkyvyOS Installer**
   ```bash
   # Login as root or user
   su -  # If not root
   
   # Download installer
   wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
   
   # Or use curl
   curl -O https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
   
   # Make executable
   chmod +x install-skyvyos.sh
   ```

4. **Run Installation**
   ```bash
   sudo ./install-skyvyos.sh
   ```

   The installation takes 10-30 minutes depending on network speed.

### Method 2: From Existing Debian System

If you have an existing Debian 12 system:

```bash
# Update existing system first
sudo apt update && sudo apt upgrade -y

# Download and run installer
wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
chmod +x install-skyvyos.sh
sudo ./install-skyvyos.sh
```

## Initial Setup

### 1. SSH Key Configuration

**Before rebooting**, set up SSH keys as password authentication will be disabled:

```bash
# On your LOCAL machine, generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to server
ssh-copy-id username@server_ip

# Or manually:
# 1. Display your public key on local machine
cat ~/.ssh/id_ed25519.pub

# 2. On the server, add it to authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste your public key, save and exit
chmod 600 ~/.ssh/authorized_keys
```

### 2. Reboot the System

```bash
sudo reboot
```

### 3. First Login

After reboot, you'll see the SkyvyOS welcome screen:

```
SkyvyOS Server 1.0

[system information displays here]
```

Login with SSH key authentication.

## Post-Installation Configuration

### Verify Installation

```bash
# Check OS version
cat /etc/os-release

# Run system info
skyvy-info

# Check service status
sudo systemctl status nginx
sudo systemctl status docker
sudo systemctl status fail2ban

# Check firewall
sudo ufw status
```

### Update System Hostname

If you want to change the hostname:

```bash
sudo hostnamectl set-hostname your-hostname
sudo nano /etc/hosts
# Update 127.0.1.1 line with new hostname
sudo reboot
```

### Configure Timezone

```bash
# List timezones
timedatectl list-timezones

# Set timezone
sudo timedatectl set-timezone Asia/Jakarta  # Example
```

### Configure Locales

```bash
sudo dpkg-reconfigure locales
# Select your preferred locales
```

## Service Configuration

### Nginx Web Server

#### Basic Configuration

Default configuration is in `/etc/nginx/sites-available/default`.

#### Create a New Site

```bash
# Create site configuration
sudo nano /etc/nginx/sites-available/mysite.com

# Add configuration:
server {
    listen 80;
    listen [::]:80;
    server_name mysite.com www.mysite.com;
    root /var/www/mysite.com;
    index index.html index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    # PHP processing (if needed)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}

# Create web root
sudo mkdir -p /var/www/mysite.com
sudo chown -R $USER:$USER /var/www/mysite.com

# Enable site
sudo ln -s /etc/nginx/sites-available/mysite.com /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### Set Up SSL with Certbot

```bash
# Get SSL certificate
sudo certbot --nginx -d mysite.com -d www.mysite.com

# Follow prompts
# Certbot will automatically configure Nginx for HTTPS

# Test auto-renewal
sudo certbot renew --dry-run
```

### Docker Configuration

#### Add User to Docker Group

```bash
sudo usermod -aG docker $USER
# Logout and login again for changes to take effect
```

#### Test Docker

```bash
docker --version
docker compose version

# Run test container
docker run hello-world
```

#### Deploy Application with Docker

Example: Deploy a Node.js application

```bash
# Create app directory
mkdir -p ~/apps/myapp
cd ~/apps/myapp

# Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  web:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./:/app
    ports:
      - "3000:3000"
    command: npm start
    restart: unless-stopped
EOF

# Start container
docker compose up -d

# View logs
docker compose logs -f
```

### Node.js Applications

#### Using Node.js Directly

```bash
# Verify Node.js
node --version
npm --version

# Create application
mkdir -p ~/apps/nodeapp
cd ~/apps/nodeapp
npm init -y
npm install express

# Create app
cat > index.js <<EOF
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('Hello from SkyvyOS!');
});

app.listen(port, () => {
    console.log(\`Server running on port \${port}\`);
});
EOF

# Run application
node index.js
```

#### Create Systemd Service

```bash
sudo nano /etc/systemd/system/nodeapp.service

# Add:
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/apps/nodeapp
ExecStart=/usr/bin/node index.js
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable nodeapp
sudo systemctl start nodeapp
sudo systemctl status nodeapp
```

### Python Applications

```bash
# Create virtual environment
python3 -m venv ~/myapp/venv
source ~/myapp/venv/bin/activate

# Install packages
pip install flask gunicorn

# Create Flask app
cat > ~/myapp/app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from SkyvyOS!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## Security Setup

### Additional Firewall Rules

```bash
# Allow custom port
sudo ufw allow 8080/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100 to any port 22

# Delete rule
sudo ufw delete allow 8080/tcp

# View numbered rules
sudo ufw status numbered

# Delete by number
sudo ufw delete 3
```

### fail2ban Management

```bash
# Check status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# View logs
sudo cat /var/log/fail2ban.log
```

### Security Audit

```bash
# Run built-in security audit
sudo skyvy-security-audit

# Check open ports
sudo ss -tulpn | grep LISTEN

# Review recent logins
last
lastlog

# Check failed login attempts
grep "Failed password" /var/log/auth.log
```

## Application Deployment

### Deploying a Static Website

```bash
# Create web directory
sudo mkdir -p /var/www/mysite
sudo chown -R $USER:$USER /var/www/mysite

# Upload files (from local machine)
scp -r ./website/* user@server:/var/www/mysite/

# Configure Nginx (see Nginx section above)
```

### Deploying a WordPress Site

```bash
# Install additional PHP modules
sudo apt install -y php-mysql php-fpm

# Install MariaDB (optional)
sudo apt install -y mariadb-server
sudo mysql_secure_installation

# Download WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo mv wordpress /var/www/mywordpress

# Configure Nginx for WordPress
# (Create appropriate site configuration)

# Set permissions
sudo chown -R www-data:www-data /var/www/mywordpress
```

## Maintenance

### System Updates

```bash
# Check for updates
sudo apt update
sudo apt list --upgradable

# Install updates
sudo apt upgrade -y

# Full upgrade (includes new packages)
sudo apt full-upgrade -y

# Clean up
sudo apt autoremove -y
sudo apt autoclean
```

### Docker Maintenance

```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Complete cleanup
docker system prune -a --volumes
```

### Log Management

```bash
# View logs
journalctl -xe  # Recent system logs
journalctl -u nginx  # Nginx logs
journalctl -u docker  # Docker logs

# Clear journal logs older than 7 days
sudo journalctl --vacuum-time=7d

# Limit journal size
sudo journalctl --vacuum-size=500M
```

### Backup

```bash
# Backup configuration files
sudo tar -czf /backup/etc-backup-$(date +%Y%m%d).tar.gz /etc/

# Backup web files
sudo tar -czf /backup/www-backup-$(date +%Y%m%d).tar.gz /var/www/

# Backup with rsync
rsync -avz /var/www/ /backup/www/
```

## Troubleshooting

### Cannot Connect via SSH

```bash
# On the server (using console access):
sudo systemctl status sshd
sudo ufw status
sudo ufw allow 22/tcp
sudo systemctl restart sshd
```

### Nginx Not Working

```bash
# Check status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Docker Issues

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# View Docker logs
sudo journalctl -u docker -n 50

# Check container logs
docker logs CONTAINER_NAME
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Find large directories
du -sh /* | sort -h

# Clean Docker
docker system prune -a --volumes

# Clean APT cache
sudo apt clean
sudo apt autoclean

# Clear old logs
sudo journalctl --vacuum-time=3d
```

### Service Won't Start

```bash
# Check service status
sudo systemctl status SERVICE_NAME

# View detailed logs
sudo journalctl -u SERVICE_NAME -n 100

# Check for port conflicts
sudo ss -tulpn | grep PORT_NUMBER

# Restart service
sudo systemctl restart SERVICE_NAME
```

## Best Practices

1. **Regular Backups**: Always maintain backups before major changes
2. **Security Updates**: Let automatic updates run, check weekly
3. **Monitoring**: Regularly check `skyvy-info` and logs
4. **Documentation**: Document all custom configurations
5. **Testing**: Test changes in development before production
6. **Firewall**: Only open required ports
7. **SSH Keys**: Never re-enable password authentication
8. **SSL**: Always use HTTPS for public-facing services

---

**Need Help?** Check the architecture documentation or create an issue on GitHub.
