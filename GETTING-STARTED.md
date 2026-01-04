# SkyvyOS Secure Server - Getting Started Guide

**Quick Start Guide for SkyvyOS Enterprise Security-Hardened Server**

## Overview

SkyvyOS Secure Server is a production-ready, security-hardened Debian-based server operating system designed for:
- 🚀 **High Performance** - Lightweight and fast
- 🔒 **Maximum Security** - Hardened by default
- 💪 **24/7 Stability** - Production-ready
- 🎯 **Ready to Deploy** - Includes web server, Docker, and runtimes

## Quick Installation

### Step 1: Install Debian Minimal

1. Download Debian 12 netinst ISO from https://www.debian.org/CD/netinst/
2. Install Debian with minimal options
3. Software selection: only **SSH server** and **standard system utilities**

### Step 2: Run SkyvyOS Installer

```bash
# Login as root
su -

# Download installer
wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/master-orchestrator.sh

# Or use local file from scripts folder
# chmod +x scripts/master-orchestrator.sh
# sudo ./scripts/master-orchestrator.sh

# Run complete installation
chmod +x master-orchestrator.sh
./master-orchestrator.sh --full
```

### Step 3: Setup SSH Key (CRITICAL!)

**BEFORE REBOOT**, add your SSH public key:

```bash
# From your local machine
ssh-copy-id admin@SERVER_IP

# Or manually:
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Paste your SSH public key, save
chmod 600 ~/.ssh/authorized_keys
```

### Step 4: Reboot

```bash
reboot
```

## What's Installed

### Web Server
- ✅ **Nginx** - HTTP/HTTPS server production-ready
- ✅ **Certbot** - Free SSL/TLS from Let's Encrypt

### Container Platform
- ✅ **Docker** - Containerization platform
- ✅ **Docker Compose** - Orchestration tool

### Programming Language Runtimes
- ✅ **Node.js 20.x LTS** - JavaScript runtime
- ✅ **Python 3.11+** - Python runtime with pip
- ✅ **PHP 8.2+** - PHP runtime with FPM
- ✅ **24+ languages** - Complete polyglot support

### Security Tools
- ✅ **nftables** - Advanced firewall (SSH, HTTP, HTTPS allowed)
- ✅ **Fail2Ban** - Intrusion prevention
- ✅ **auditd** - Forensic logging
- ✅ **AIDE** - File integrity monitoring
- ✅ **Automatic Updates** - Security patches automatic

### Monitoring & Utilities
- ✅ **htop, iotop, iftop** - Monitoring tools
- ✅ **git, curl, wget, vim** - Development tools
- ✅ **rsync, borgbackup** - Backup tools

## Default Firewall Configuration

| Port | Service | Status |
|------|---------|--------|
| 22   | SSH     | ✅ Open |
| 80   | HTTP    | ✅ Open |
| 443  | HTTPS   | ✅ Open |
| Other | All    | ❌ Closed (default deny) |

To open additional ports:
```bash
# Edit nftables config
sudo nano /etc/nftables.conf

# Add rule under INPUT chain
tcp dport 3000 accept comment "Node.js app"

# Reload firewall
sudo nft -f /etc/nftables.conf
```

## Essential Commands

```bash
# System information
skyvyos-info

# Firewall status
sudo nft list ruleset

# Service status
sudo systemctl status nginx
sudo systemctl status docker

# Security audit
sudo skyvy-security-audit

# Update system
sudo apt update && sudo apt upgrade

# View logs
sudo journalctl -xe
```

## Deploy Applications

### Deploy Static Website

```bash
# Upload files to /var/www/
sudo mkdir -p /var/www/mysite
sudo chown -R $USER:$USER /var/www/mysite

# Configure Nginx
sudo nano /etc/nginx/sites-available/mysite
sudo ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Deploy with Docker

```bash
# Example: Deploy Node.js app
mkdir ~/myapp
cd ~/myapp

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

# Run
docker compose up -d
docker compose logs -f
```

### Deploy Node.js Application

```bash
# Install PM2 (process manager)
npm install -g pm2

# Run application
pm2 start app.js
pm2 startup  # Auto-start on boot
pm2 save
```

## Setup SSL/HTTPS

```bash
# Install SSL certificate
sudo certbot --nginx -d domain.com -d www.domain.com

# Auto-renewal is already configured
sudo certbot renew --dry-run
```

## VM Template Creation

### How to Create Template

1. Install SkyvyOS on VM
2. Run preparation script:
```bash
wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/prepare-vm-template.sh
chmod +x prepare-vm-template.sh
sudo ./prepare-vm-template.sh
sudo shutdown -h now
```
3. In hypervisor: Convert VM to template/master image

### Deploy from Template

1. Clone template VM
2. Choose "Full Clone"
3. Configure network (Cloud-Init or manual)
4. Start VM

Full details in [docs/VM-TEMPLATE-GUIDE.md](docs/VM-TEMPLATE-GUIDE.md)

## Important Files

- **Main scripts**: `scripts/master-orchestrator.sh`, `scripts/install-skyvyos.sh`
- **Security**: `scripts/security-hardening.sh`
- **VM Template**: `scripts/prepare-vm-template.sh`
- **Package list**: `config/packages.list`
- **Documentation**: `docs/` folder

## Complete Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Overview & quick start |
| [DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) | Complete deployment guide |
| [SECURITY-ARCHITECTURE.md](docs/SECURITY-ARCHITECTURE.md) | System architecture & threat model |
| [NETWORK-SECURITY.md](docs/NETWORK-SECURITY.md) | Advanced firewall configuration |
| [PROGRAMMING-LANGUAGES.md](docs/PROGRAMMING-LANGUAGES.md) | All 24+ supported languages |
| [VM-TEMPLATE-GUIDE.md](docs/VM-TEMPLATE-GUIDE.md) | Multi-platform VM guide |
| [QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md) | Command reference |

## Security Notes

⚠️ **CRITICAL**:
- SSH password authentication is **DISABLED**
- Only SSH key authentication allowed
- Root login is **DISABLED**
- **Ensure SSH key is configured before reboot!**

## Troubleshooting

**Cannot SSH?**
```bash
# Check firewall
sudo nft list ruleset | grep ssh

# Check SSH service
sudo systemctl status sshd
sudo journalctl -u sshd -n 50
```

**Service not running?**
```bash
# Check status
sudo systemctl status SERVICE_NAME

# View logs
sudo journalctl -u SERVICE_NAME -n 50

# Restart service
sudo systemctl restart SERVICE_NAME
```

**Disk full?**
```bash
# Clean Docker
docker system prune -a

# Clean APT cache
sudo apt clean

# Clean old logs
sudo journalctl --vacuum-time=3d
```

## Use Cases

✅ Web hosting (Nginx + SSL)  
✅ Application server (Node.js, Python, PHP, Go, Rust, etc.)  
✅ Bot hosting (Discord, Telegram, WhatsApp)  
✅ Docker container host  
✅ Development/staging server  
✅ VM template for rapid deployment  
✅ Polyglot development environment (24+ languages)  

---

**SkyvyOS Secure Server** - Lightweight, Secure, Stable. Production-ready! 🚀

For detailed guides, see `docs/DEPLOYMENT-GUIDE.md` and other documentation files.
