# 🛡️ SkyvyOS Secure Server

<div align="center">
  <img src="branding/logo.png" alt="SkyvyOS Logo" width="200">
  <br><br>

  [![License](https://img.shields.io/badge/License-GPL%20v3.0-blue?style=for-the-badge)](LICENSE)
  [![Based on](https://img.shields.io/badge/Based%20on-Debian%2012-red?style=for-the-badge&logo=debian)](https://debian.org)
  [![Security](https://img.shields.io/badge/Security-Hardened-green?style=for-the-badge&logo=linux)](https://cisecurity.org)
  [![Platform](https://img.shields.io/badge/Platform-Server-lightgrey?style=for-the-badge&logo=server)](https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server)

  **Enterprise-Grade Security-Hardened Linux Distribution**
  <p><i>Built for Stability, Engineered for Security, Optimized for Production</i></p>
</div>

---

## 📖 Overview

**SkyvyOS Secure Server** is a specialized, security-focused Linux distribution built upon the robust foundation of **Debian 12 (Bookworm)**. It is essentially a "hardened-by-default" operating system designed to bridge the gap between a fresh minimal installation and a production-grade enterprise server.

Unlike standard distributions that prioritize convenience over security, SkyvyOS implements strict security controls immediately upon installation, including **CIS (Center for Internet Security)** compliant kernel parameters, strict firewall rules, and mandatory access controls.

### 🎯 Core Objectives
*   **Minimize Attack Surface**: Strip down to bare essentials.
*   **Enforce Compliance**: Apply CIS Benchmark configurations automatically.
*   **Proactive Defense**: Intrusion prevention and file integrity monitoring out-of-the-box.
*   **Rapid Deployment**: Automated provisioning for physical servers and VMs.

---

## 🌟 Key Features

| Feature category | Description |
|------------------|-------------|
| **🛡️ Network Security** | **nftables** stateful firewall with default-deny policy. **Fail2Ban** pre-configured for SSH and Web attacks. |
| **🔒 System Hardening** | **Kernel Hardening** (ASLR, Ptrace scope, restricted dmesg). **AppArmor** profiles enabled. **Auditd** for comprehensive system logging. |
| **🔑 Identification & Auth** | **SSH Hardening** (Key-only auth, Root login disabled, 2FA ready). Pre-configured **PAM** policies. |
| **🚀 Production Stack** | **Nginx** (High Performance Web Server), **Docker** + Compose (Containerization), **Certbot** (Auto-SSL), and **Unattended Upgrades**. |
| **📦 Universal Runtime** | Pre-installed environments for **Python 3**, **Node.js LTS**, **PHP 8**, **Go**, **Rust**, **Java**, and more. |
| **☁️ Cloud & VM Ready** | Optimized templates for **Proxmox VE**, **VMware ESXi**, and **VirtualBox**. Includes `cloud-init` and guest agents. |

---

## 📋 System Requirements

To ensure optimal performance and security, the following resources are recommended:

| Component | Minimum Specification | Recommended Specification |
|-----------|-----------------------|---------------------------|
| **Processor** | 1 Core (x86_64) | 2+ Cores (for heavy workloads) |
| **Memory** | 512 MB RAM | 2 GB+ RAM |
| **Storage** | 10 GB HDD/SSD | 20 GB+ NVMe SSD |
| **Network** | Ethernet (Internet required for install) | Static IP configuration |
| **Base OS** | Debian 12 Minimal | Debian 12 Netinst |

---

## 🛠️ Installation Guide

### Method 1: Automated Installation (Recommended)
This method transforms a fresh Debian installation into SkyvyOS. Perfect for VPS, bare metal, or existing VMs.

1.  **Install Debian 12 Minimal**: Download the [Debian Netinst ISO](https://www.debian.org/distrib/netinst). Install with specific settings:
    *   **Uncheck** "Debian desktop environment"
    *   **Uncheck** "GNOME" (or any GUI)
    *   **Check** "SSH server" and "Standard system utilities"

2.  **Login to your server** as `root` (or a sudo user).

3.  **Execute the Installer**:
    ```bash
    # Update and install git
    sudo apt update && sudo apt install -y git

    # Clone the repository
    git clone https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server.git
    cd SkyvyOS-Secure-Server

    # Run the automated installer
    sudo bash scripts/install-skyvyos.sh
    ```

4.  **Reboot**:
    ```bash
    sudo reboot
    ```

### Method 2: Build Custom ISO
For mass deployment or offline installation, you can build a custom bootable ISO.

1.  **Prepare Build Environment**: (Run on a Debian/Ubuntu machine)
    ```bash
    sudo apt update && sudo apt install -y live-build debootstrap squashfs-tools genisoimage syslinux isolinux xorriso
    ```

2.  **Build the ISO**:
    ```bash
    git clone https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server.git
    cd SkyvyOS-Secure-Server
    sudo bash scripts/build-skyvyos-iso.sh
    ```

3.  **Locate Output**: The ISO will be generated in the `build/` directory:
    `SkyvyOS-Secure-Server-YYYYMMDD-HHMMSS.iso`

### Method 3: Virtual Machine Template
Streamline deployment on Proxmox or VMware by creating a reusable template.

1.  Perfom **Method 1** inside a VM.
2.  **Do not create user-specific data** yet.
3.  Run the preparation script:
    ```bash
    sudo bash scripts/prepare-vm-template.sh
    ```
    *(For Proxmox specifically: `sudo bash scripts/prepare-proxmox-template.sh`)*
4.  Shutdown and convert the VM to a Template.

---

## 🔧 Post-Installation Management

### 1. Administrative Access
*   **Root Login**: DISABLED by default.
*   **Password Auth**: DISABLED by default.
*   **Access**: You **must** use an SSH Key.
    ```bash
    # From your local machine
    ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server-ip
    ```

### 2. System Monitoring
SkyvyOS includes custom tools for rapid status checks:
```bash
# Dashboard view of system health, load, and services
skyvyos-info
```

### 3. Security Auditing
Perform a comprehensive security scan against CIS benchmarks:
```bash
sudo skyvy-security-audit
```

### 4. Firewall Management
The firewall acts on a **Default Deny** policy. Only SSH (22), HTTP (80), and HTTPS (443) are open.

**Opening a new port (e.g., 8080):**
```bash
# Allow TCP traffic on port 8080
sudo nft add rule inet filter input tcp dport 8080 accept

# Make changes persistent
sudo nft list ruleset > /etc/nftables.conf
```

---

## 📁 Project Structure

```
SkyvyOS-Secure-Server/
├── 📂 branding/           # Custom logos, MOTD, and OS release info
├── 📂 config/             # Hardened configuration files
│   ├── nftables.conf      # Stateful firewall ruleset
│   ├── sshd_config        # SSH server hardening
│   └── sysctl-hardening   # Kernel parameter optimizations
├── 📂 docs/               # Detailed documentation
│   ├── ARCHITECTURE.md    # System design principles
│   ├── SECURITY.md        # Security implementation details
│   └── DEPLOYMENT.md      # Extended deployment scenarios
├── 📂 scripts/            # Automation scripts
│   ├── install-skyvyos.sh     # Master installer
│   ├── build-skyvyos-iso.sh   # ISO generation tool
│   └── skyvy-security-audit   # Vulnerability scanner
└── 📄 README.md           # This documentation
```

---

## 🤝 Contributing

We welcome contributions from the open-source community!

1.  **Fork** the repository.
2.  Create a feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a **Pull Request**.

---

## 📜 License

Distributed under the **GNU General Public License v3.0**. See `LICENSE` for more information.

---

<div align="center">
  <sub>Designed and Maintained by MuhammadLutfiMuzakiiVY</sub>
</div>
