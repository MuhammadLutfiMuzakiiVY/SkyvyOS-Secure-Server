# SkyvyOS Server

**Custom Debian-based Server Operating System**

SkyvyOS Server is a lightweight, secure, and stable server operating system built on Debian Stable. Designed for production deployments, it's optimized for websites, bots, and application servers with 24/7 uptime requirements.

## Features

✨ **Lightweight & Fast** - Minimal footprint with only essential services  
🔒 **Security Hardened** - SSH key-only auth, UFW firewall, fail2ban, automatic security updates  
🚀 **Production Ready** - Pre-configured Nginx, Docker, and common runtimes  
📦 **Easy Deployment** - Automated installation from Debian minimal  
☁️ **VM Template Ready** - Compatible with KVM, VMware, VirtualBox, Hyper-V  
🎯 **CLI Only** - No GUI overhead, built for server environments  

## Default Stack

- **Web Server**: Nginx
- **Containerization**: Docker & Docker Compose
- **Runtimes**: Node.js LTS, Python 3, PHP 8.x
- **Security**: UFW, fail2ban, unattended-upgrades
- **Tools**: Git, curl, wget, vim, htop, net-tools
- **TLS**: Certbot for Let's Encrypt certificates

## System Requirements

- **Base**: Debian 12 (Bookworm) minimal installation
- **RAM**: Minimum 512 MB (1 GB+ recommended)
- **Disk**: 5 GB minimum (10 GB+ recommended)
- **CPU**: 1 core minimum
- **Network**: Internet connection for installation

## Quick Start

### 1. Install Debian Minimal

Start with a fresh Debian 12 (Bookworm) minimal installation (netinst ISO recommended).

### 2. Download SkyvyOS Installer

```bash
wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
chmod +x install-skyvyos.sh
```

### 3. Run Installation

```bash
sudo ./install-skyvyos.sh
```

The installer will:
- Update system packages
- Install all required software
- Apply security hardening
- Configure services
- Setup SkyvyOS branding
- Configure firewall

### 4. Reboot

```bash
sudo reboot
```

## Post-Installation

After reboot, you'll see the SkyvyOS Server login screen. The system is ready for:

- **Web hosting**: Nginx is configured and running
- **Application deployment**: Docker ready for containers
- **Development**: Node.js, Python, and PHP installed
- **Security**: SSH hardened, firewall active, fail2ban monitoring

## Documentation

- [Architecture Overview](docs/SkyvyOS-Architecture.md)
- [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)
- [Proxmox Template Setup](docs/proxmox-deployment.md)

## Directory Structure

```
SkyvyOS Server/
├── scripts/
│   ├── install-skyvyos.sh          # Main installation script
│   ├── security-hardening.sh       # Security configuration
│   └── prepare-vm-template.sh      # VM template preparation
├── config/
│   ├── packages.list               # Package definitions
│   ├── sshd_config.template        # SSH hardening
│   ├── ufw-rules.sh                # Firewall rules
│   ├── sysctl-hardening.conf       # Kernel security
│   └── limits.conf                 # Resource limits
├── branding/
│   ├── os-release                  # OS identification
│   ├── motd                        # Message of the day
│   ├── issue                       # Pre-login banner
│   └── skyvy-info.sh               # System info script
└── docs/
    ├── SkyvyOS-Architecture.md     # Architecture docs
    ├── DEPLOYMENT-GUIDE.md         # Deployment guide
    └── VM-TEMPLATE-GUIDE.md        # VM template guide
```

## Firewall Configuration

By default, SkyvyOS Server has a strict firewall policy:

- **SSH (22)**: Allowed
- **HTTP (80)**: Allowed
- **HTTPS (443)**: Allowed
- **All other incoming**: Denied

To open additional ports:

```bash
sudo ufw allow PORT_NUMBER
sudo ufw reload
```

## Service Management

All services are managed via systemd:

```bash
# Check service status
sudo systemctl status nginx
sudo systemctl status docker

# Start/stop/restart services
sudo systemctl start SERVICE_NAME
sudo systemctl stop SERVICE_NAME
sudo systemctl restart SERVICE_NAME
```

## Security Features

- **SSH Hardening**: Root login disabled, password authentication disabled
- **Firewall**: UFW with default deny policy
- **Intrusion Prevention**: fail2ban monitoring SSH, Nginx
- **Automatic Updates**: Security patches applied automatically
- **Kernel Hardening**: sysctl security parameters optimized

## Contributing

This is a personal/custom OS project. Feel free to fork and adapt for your needs.

## License

MIT License - Free to use and modify

## Support

For issues or questions, consult the documentation in the `docs/` directory.

---

**SkyvyOS Server** - Built for stability, secured by default, optimized for production.
