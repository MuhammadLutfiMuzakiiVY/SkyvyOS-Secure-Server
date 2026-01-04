# SkyvyOS Server - Quick Reference

**Quick commands and configuration snippets for daily SkyvyOS Server management.**

## System Information

```bash
# SkyvyOS system info
skyvy-info

# OS version
cat /etc/os-release

# Kernel version
uname -r

# System uptime
uptime

# Resource usage
htop
```

## Service Management

```bash
# Check service status
sudo systemctl status nginx
sudo systemctl status docker
sudo systemctl status fail2ban

# Start/stop/restart services
sudo systemctl start SERVICE
sudo systemctl stop SERVICE
sudo systemctl restart SERVICE
sudo systemctl reload SERVICE

# Enable/disable on boot
sudo systemctl enable SERVICE
sudo systemctl disable SERVICE

# View service logs
sudo journalctl -u SERVICE -n 50
sudo journalctl -u SERVICE -f  # Follow logs
```

## Firewall (UFW)

```bash
# Check status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Allow ports
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp comment 'My App'

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Delete rule
sudo ufw delete allow 3000/tcp
sudo ufw delete 3  # By number

# Enable/disable
sudo ufw enable
sudo ufw disable

# Reset to defaults
sudo ufw --force reset
```

## fail2ban

```bash
# Check status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# View banned IPs
sudo fail2ban-client get sshd banned

# Reload configuration
sudo fail2ban-client reload

# View logs
sudo tail -f /var/log/fail2ban.log
```

## Docker

```bash
# Container management
docker ps                    # List running containers
docker ps -a                 # List all containers
docker start CONTAINER
docker stop CONTAINER
docker restart CONTAINER
docker logs CONTAINER
docker logs -f CONTAINER     # Follow logs

# Image management
docker images
docker pull IMAGE
docker rmi IMAGE

# Docker Compose
docker compose up -d         # Start in background
docker compose down          # Stop and remove
docker compose ps            # List services
docker compose logs -f       # Follow logs

# System cleanup
docker system prune          # Remove unused data
docker system prune -a       # Remove all unused images
docker volume prune          # Remove unused volumes
```

## Nginx

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Enable site
sudo ln -s /etc/nginx/sites-available/SITE /etc/nginx/sites-enabled/

# Disable site
sudo rm /etc/nginx/sites-enabled/SITE
```

## SSL Certificates (Certbot)

```bash
# Get certificate
sudo certbot --nginx -d example.com -d www.example.com

# Renew all certificates
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run

# List certificates
sudo certbot certificates

# Revoke  certificate
sudo certbot revoke --cert-path /etc/letsencrypt/live/example.com/cert.pem
```

## Package Management

```bash
# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade

# Full system upgrade
sudo apt full-upgrade

# Install package
sudo apt install PACKAGE

# Remove package
sudo apt remove PACKAGE
sudo apt purge PACKAGE       # Remove with config

# Clean up
sudo apt autoremove
sudo apt autoclean

# Search packages
apt search KEYWORD

# Show package info
apt show PACKAGE
```

## User Management

```bash
# Add user
sudo adduser USERNAME

# Add user to group
sudo usermod -aG GROUP USERNAME

# Add to Docker group
sudo usermod -aG docker USERNAME

# Add to sudo group
sudo usermod -aG sudo USERNAME

# Delete user
sudo deluser USERNAME
sudo deluser --remove-home USERNAME

# List groups
groups USERNAME
```

## Network

```bash
# Show IP address
ip addr show
hostname -I

# Show network stats
ip -s link

# Show listening ports
sudo ss -tulpn | grep LISTEN

# Show established connections
sudo ss -tupn | grep ESTAB

# Test connection
ping google.com
ping -c 4 1.1.1.1

# DNS lookup
nslookup example.com
dig example.com
```

## Disk Usage

```bash
# Disk space
df -h

# Directory size
du -sh /var/www
du -sh *

# Find large files
find / -type f -size +100M 2>/dev/null

# Interactive disk usage
ncdu /

# Check inodes
df -i
```

## Logs

```bash
# System logs
sudo journalctl -xe          # Recent with explanation
sudo journalctl -n 100       # Last 100 lines
sudo journalctl -f           # Follow
sudo journalctl --since "1 hour ago"
sudo journalctl --since "2023-01-01"

# Service logs
sudo journalctl -u nginx -n 50
sudo journalctl -u docker -f

# Clear old logs
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=500M

# Other logs
sudo tail -f /var/log/syslog
sudo tail -f /var/log/auth.log
```

## Security Audit

```bash
# SkyvyOS security audit
sudo skyvy-security-audit

# Check open ports
sudo ss -tulpn

# Check failed logins
grep "Failed password" /var/log/auth.log | tail -20

# Recent logins
last
lastlog

# Who is logged in
who
w
```

## Backup

```bash
# Backup website files
sudo tar -czf /backup/www-$(date +%F).tar.gz /var/www

# Backup configs
sudo tar -czf /backup/etc-$(date +%F).tar.gz /etc

# Backup with rsync
rsync -avz /var/www/ /backup/www/

# Restore from tar
sudo tar -xzf /backup/www-2024-01-01.tar.gz -C /
```

## Process Management

```bash
# List processes
ps aux
ps aux | grep nginx

# Process tree
pstree

# Interactive process manager
htop

# Kill process
kill PID
kill -9 PID              # Force kill
killall PROCESS_NAME

# System load
top
uptime
```

## SSH

```bash
# Connect to server
ssh user@server

# Copy file to server
scp file.txt user@server:/path/

# Copy directory to server
scp -r folder/ user@server:/path/

# Reverse copy (from server)
scp user@server:/path/file.txt .

# Generate SSH key
ssh-keygen -t ed25519 -C "email@example.com"

# Copy SSH key to server
ssh-copy-id user@server
```

## Performance Monitoring

```bash
# CPU usage
htop
top
mpstat

# Memory usage
free -h
vmstat 1

# Disk I/O
iotop
iostat

# Network usage
iftop
nethogs

# System stats
sar

# All-in-one monitor
nmon
```

## System Administration

```bash
# Reboot system
sudo reboot

# Shutdown
sudo shutdown -h now
sudo shutdown -h +10         # Shutdown in 10 min

# Check system time
timedatectl

# Set timezone
sudo timedatectl set-timezone Asia/Jakarta

# Configure locales
sudo dpkg-reconfigure locales

# Set hostname
sudo hostnamectl set-hostname newhostname
```

## Node.js Applications

```bash
# Check versions
node --version
npm --version

# Install packages
npm install
npm install -g pm2           # Process manager

# Using PM2
pm2 start app.js
pm2 stop app
pm2 restart app
pm2 list
pm2 logs app
pm2 startup                  # Auto-start on boot
pm2 save
```

## Python Applications

```bash
# Python version
python3 --version

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Using systemd service
sudo systemctl start myapp
sudo systemctl enable myapp
```

## Quick Fixes

### Can't SSH
```bash
# On server (console access):
sudo systemctl restart sshd
sudo ufw allow 22/tcp
```

### Nginx won't start
```bash
sudo nginx -t               # Test config
sudo systemctl status nginx
sudo tail /var/log/nginx/error.log
```

### Out of Disk Space
```bash
docker system prune -a --volumes
sudo apt clean
sudo journalctl --vacuum-time=3d
```

### Service won't start
```bash
sudo systemctl status SERVICE
sudo journalctl -u SERVICE -n 50
```

## File Locations

- **Nginx configs**: `/etc/nginx/`
- **Nginx sites**: `/etc/nginx/sites-available/`, `/etc/nginx/sites-enabled/`
- **Web root**: `/var/www/`
- **SSH config**: `/etc/ssh/sshd_config.d/`
- **Firewall rules**: `/etc/ufw/`
- **Systemd services**: `/etc/systemd/system/`
- **Logs**: `/var/log/`
- **Docker data**: `/var/lib/docker/`

## Useful Aliases (Add to ~/.bashrc)

```bash
alias ll='ls -lah'
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='sudo ss -tulpn | grep LISTEN'
alias dockerclean='docker system prune -a'
alias logs='sudo journalctl -f'
alias sysinfo='skyvy-info'
```

---

**Save this guide** for quick reference when managing your SkyvyOS Server!
