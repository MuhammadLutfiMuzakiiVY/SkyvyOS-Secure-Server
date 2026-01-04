# SkyvyOS Server Architecture

## Overview

SkyvyOS Server is a custom Debian-based server operating system optimized for production deployments. It follows a minimalist philosophy, including only essential components while maintaining enterprise-grade security and reliability.

## Design Philosophy

1. **Minimalism**: Only essential packages and services
2. **Security First**: Hardened by default, zero-trust approach
3. **Stability**: Based on Debian Stable for long-term reliability
4. **Performance**: Optimized for server workloads, no GUI overhead
5. **Automation**: Fully automated installation and configuration

## System Architecture

### Base System

```
┌─────────────────────────────────────────────────────────┐
│                    Applications Layer                    │
│  (User apps, Docker containers, Web services)           │
├─────────────────────────────────────────────────────────┤
│                   Platform Services                      │
│  Nginx │ Docker │ Node.js │ Python │ PHP │ Certbot     │
├─────────────────────────────────────────────────────────┤
│                   Security Layer                         │
│  UFW Firewall │ fail2ban │ SSH Hardening │ AppArmor    │
├─────────────────────────────────────────────────────────┤
│                   Core Services                          │
│  systemd │ rsyslog │ cron │ Network Manager            │
├─────────────────────────────────────────────────────────┤
│                   Kernel & Hardware                      │
│  Linux Kernel │ Device Drivers │ Filesystem (ext4)     │
└─────────────────────────────────────────────────────────┘
```

### Filesystem Structure

SkyvyOS follows the Filesystem Hierarchy Standard (FHS):

```
/
├── bin/          → /usr/bin (binaries)
├── boot/         Boot loader files, kernel
├── dev/          Device files
├── etc/          System configuration
│   ├── nginx/    Nginx configuration
│   ├── ssh/      SSH configuration
│   ├── ufw/      Firewall rules
│   └── systemd/  Service units
├── home/         User home directories
├── lib/          → /usr/lib (libraries)
├── opt/          Optional software packages
├── root/         Root user home
├── run/          Runtime data
├── srv/          Service data (web content)
│   └── www/      Default web root
├── tmp/          Temporary files (cleared on boot)
├── usr/          User programs and data
│   ├── bin/      User binaries
│   ├── lib/      Libraries
│   ├── local/    Locally installed software
│   └── share/    Shared data
└── var/          Variable data
    ├── log/      Log files
    ├── www/      Web server files (Nginx default)
    └── lib/      Application state data
        └── docker/ Docker containers/images
```

## Core Services

### systemd (Init System)

- **Purpose**: Service management, process supervision
- **Key Features**:
  - Parallel service startup
  - Service dependency handling
  - Socket activation
  - Timer units (cron replacement)

### Networking

- **Network Manager**: NetworkManager or systemd-networkd
- **DNS**: systemd-resolved
- **Firewall**: UFW (Uncomplicated Firewall) with iptables backend

### Security Services

#### UFW Firewall
- **Default Policy**: Deny all incoming, allow all outgoing
- **Allowed Ports**: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Backend**: iptables with netfilter

#### fail2ban
- **Purpose**: Intrusion prevention system
- **Monitors**: SSH, Nginx, custom services
- **Action**: Automatic IP blocking after repeated failures

#### SSH Hardening
- **Authentication**: Key-based only, passwords disabled
- **Access**: Root login disabled
- **Encryption**: Strong ciphers only
- **Monitoring**: fail2ban integration

### Web Server Stack

#### Nginx
- **Role**: HTTP/HTTPS server, reverse proxy
- **Configuration**: Optimized for server workloads
- **Features**: 
  - HTTP/2 support
  - SSL/TLS termination
  - Load balancing capabilities
  - Static file serving

#### Certbot
- **Purpose**: Automated SSL/TLS certificate management
- **Provider**: Let's Encrypt
- **Auto-renewal**: Configured via systemd timer

### Container Platform

#### Docker
- **Version**: Latest Docker CE
- **Components**:
  - Docker Engine
  - Docker CLI
  - containerd
  - Docker Compose plugin
- **Storage Driver**: overlay2
- **Network**: Bridge mode by default

### Runtime Environments

#### Node.js
- **Version**: LTS (20.x)
- **Package Manager**: npm (included)
- **Use Cases**: JavaScript applications, APIs

#### Python 3
- **Version**: Debian stable version (3.11+)
- **Tools**: pip, venv, setuptools
- **Use Cases**: Scripts, web apps, automation

#### PHP
- **Version**: 8.x (Debian stable)
- **SAPI**: PHP-FPM for Nginx integration
- **Extensions**: MySQL, cURL, GD, mbstring, XML, ZIP

## Security Architecture

### Defense in Depth

```
Layer 1: Network Firewall (UFW)
         ↓
Layer 2: Intrusion Prevention (fail2ban)
         ↓
Layer 3: SSH Hardening (key-only auth)
         ↓
Layer 4: Kernel Hardening (sysctl)
         ↓
Layer 5: AppArmor (application confinement)
         ↓
Layer 6: Regular Security Updates
```

### Security Features

1. **Network Security**
   - Firewall with whitelist approach
   - SYN flood protection
   - IP spoofing protection
   - ICMP rate limiting

2. **Access Control**
   - SSH key-only authentication
   - No root SSH login
   - fail2ban active monitoring
   - Strong password policies

3. **System Hardening**
   - Kernel parameters optimized for security
   - Unnecessary services disabled
   - File permissions secured
   - Core dumps disabled

4. **Automatic Updates**
   - unattended-upgrades for security patches
   - Daily update checks
   - Automatic security-only updates

## Package Management

### APT (Advanced Package Tool)

- **Base**: Debian package manager
- **Repositories**:
  - Debian Stable (main)
  - Debian Security
  - Docker official repository
  - NodeSource repository (Node.js)

### Package Categories

1. **Essential System**
   - systemd, dbus, networking tools
   - Core utilities (vim, htop, git)

2. **Security**
   - UFW, fail2ban, AppArmor
   - unattended-upgrades

3. **Development**
   - build-essential, gcc, make
   - Git, pkg-config

4. **Server Applications**
   - Nginx, Docker, Certbot
   - Runtime environments

## Resource Management

### Memory Management

- **Swappiness**: 10 (prefer RAM over swap)
- **OOM Killer**: Configured to protect critical services
- **Caching**: Aggressive disk cache for performance

### Process Management

- **Limits**:
  - Max processes: 32768
  - Max file descriptors: 65535
  - Core dumps: Disabled

### Disk I/O

- **Filesystem**: ext4 with journaling
- **Mount Options**: noatime for performance
- **Log Rotation**: Automated via logrotate

## Service Management

### systemd Units

Enable/disable services:
```bash
systemctl enable SERVICE_NAME   # Start on boot
systemctl disable SERVICE_NAME  # Don't start on boot
```

Start/stop services:
```bash
systemctl start SERVICE_NAME
systemctl stop SERVICE_NAME
systemctl restart SERVICE_NAME
```

View status:
```bash
systemctl status SERVICE_NAME
journalctl -u SERVICE_NAME  # View logs
```

### Default Enabled Services

- sshd (OpenSSH server)
- nginx (Web server)
- docker (Container platform)
- fail2ban (Intrusion prevention)
- ufw (Firewall)
- rsyslog (System logging)
- cron (Scheduled tasks)
- unattended-upgrades (Auto updates)

## Monitoring & Logging

### Log Files

- **System Logs**: `/var/log/syslog`
- **Authentication**: `/var/log/auth.log`
- **Kernel**: `/var/log/kern.log`
- **Nginx Access**: `/var/log/nginx/access.log`
- **Nginx Error**: `/var/log/nginx/error.log`
- **Docker**: `journalctl -u docker`

### Log Rotation

- **Tool**: logrotate
- **Rotation**: Daily or when size exceeds limit
- **Retention**: 4 weeks by default
- **Compression**: gzip for old logs

### Monitoring Tools

- **htop**: Interactive process viewer
- **iotop**: Disk I/O monitor
- **iftop**: Network bandwidth monitor
- **sysstat**: System performance tools
- **nmon**: System monitor

## Network Configuration

### Ports

| Port | Service | Protocol | Purpose          |
|------|---------|----------|------------------|
| 22   | SSH     | TCP      | Remote access    |
| 80   | HTTP    | TCP      | Web server       |
| 443  | HTTPS   | TCP      | Secure web       |

### Firewall Rules

Default rules in `/etc/ufw/`:
- Allow SSH (22/tcp)
- Allow HTTP (80/tcp)
- Allow HTTPS (443/tcp)
- Deny all other incoming
- Allow all outgoing

## Deployment Models

### Bare Metal

- Direct installation on physical server
- Full hardware access
- Maximum performance

### Virtual Machine (Any Platform)

- Recommended for most deployments
- Easy backup and snapshots
- Template support for rapid deployment
- Compatible with KVM, VMware, VirtualBox, Hyper-V, etc.

### Container Host

- Docker as primary application platform
- Multiple isolated applications
- Resource efficiency

## Scalability Considerations

### Horizontal Scaling

- Multiple SkyvyOS instances behind load balancer
- Shared storage for stateful applications
- Database replication/clustering

### Vertical Scaling

- Increase VM resources (CPU, RAM)
- Expand disk storage
- Optimize application configuration

## Update Strategy

### Security Updates

- **Frequency**: Automatic daily checks
- **Application**: Automatic for security patches
- **Reboot**: Not automatic (manual control)

### System Upgrades

- **Debian Version**: Manual upgrade to new Debian releases
- **Testing**: Required before production upgrade
- **Rollback**: VM snapshots recommended

## Backup Recommendations

### System Backup

- VM snapshots (Proxmox)
- Full disk images
- Configuration files in `/etc/`

### Application Data

- Database dumps
- Docker volumes
- `/srv/` and `/var/www/` directories

### Backup Tools Included

- **borgbackup**: Deduplicating backup solution
- **duplicity**: Encrypted backup to cloud
- **rsync**: File synchronization

## Performance Tuning

### Kernel Parameters

Optimized in `/etc/sysctl.d/99-skyvyos-security.conf`:
- Network buffer sizes
- TCP/IP stack tuning
- Memory management

### Service Configuration

- Nginx: Worker processes = CPU cores
- Docker: Storage driver optimized for performance
- PHP-FPM: Process manager tuned for load

## Troubleshooting

### Common Issues

1. **Cannot SSH after installation**
   - Ensure SSH keys are properly configured
   - Check firewall rules: `sudo ufw status`

2. **Service won't start**
   - Check status: `systemctl status SERVICE`
   - View logs: `journalctl -u SERVICE -n 50`

3. **Out of disk space**
   - Clean Docker: `docker system prune -a`
   - Clean APT cache: `apt-get clean`

### Diagnostic Commands

```bash
# System overview
skyvy-info

# Service status
systemctl status

# Firewall status
sudo ufw status verbose

# Network connections
sudo ss -tulpn

# Disk usage
df -h
ncdu /

# Memory usage
free -h

# Process list
htop
```

## Future Enhancements

Potential additions for future versions:

- Database servers (PostgreSQL, MariaDB)
- Monitoring stack (Prometheus, Grafana)
- Container orchestration (Kubernetes)
- Configuration management (Ansible)
- Network mesh capabilities
- Advanced security (SELinux, hardened kernel)

---

**SkyvyOS Server** - Architected for reliability, secured by design.
