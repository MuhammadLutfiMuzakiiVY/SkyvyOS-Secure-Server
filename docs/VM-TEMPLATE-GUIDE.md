# SkyvyOS Server - VM Template & Virtualization Guide

This guide provides step-by-step instructions for deploying SkyvyOS Server as a virtual machine and creating reusable templates across various virtualization platforms.

## Supported Platforms

SkyvyOS Server works with any standard virtualization platform:
- ✅ KVM/QEMU
- ✅ VMware (ESXi, Workstation, Fusion)
- ✅ VirtualBox
- ✅ Hyper-V
- ✅ Cloud platforms (AWS, GCP, Azure, etc.)

## Table of Contents

1. [Initial VM Creation](#initial-vm-creation)
2. [SkyvyOS Installation](#skyvyos-installation)
3. [Converting to Template](#converting-to-template)
4. [Deploying from Template](#deploying-from-template)
5. [Cloud-Init Configuration](#cloud-init-configuration)
6. [Best Practices](#best-practices)

## Initial VM Creation

### Recommended VM Specifications

**Minimum**:
- CPU: 1 core
- RAM: 1024 MB
- Disk: 10 GB (thin provisioned recommended)
- Network: Bridged or NAT

**Recommended for Production**:
- CPU: 2 cores
- RAM: 2048 MB
- Disk: 20 GB SSD (thin provisioned)
- Network: Bridged with static IP

### Step 1: Download Debian Netinst ISO

1. Download Debian 12 (Bookworm) netinst ISO:
   ```
   https://www.debian.org/CD/netinst/
   ```

2. Upload ISO to your virtualization platform's datastore/library

### Step 2: Create New VM

**General Settings**:
- Name: `skyvyos-template` (or your choice)
- OS Type: Linux, Debian 64-bit
- Version: Debian 11/12 or Linux 5.x/6.x kernel

**Hardware Settings**:
- CPU: 1-2 cores
- RAM: 1024-2048 MB
- Disk: 10-20 GB, thin provisioned if possible
- Network: VirtIO/VMXNET3 for best performance
- SCSI Controller: LSI Logic or VirtIO SCSI

**Additional Options** (if available):
- Enable virtualization extensions (VT-x/AMD-V)
- Enable nested virtualization (if running containers)
- Install guest tools/additions after OS installation

### Step 3: Install Debian Minimal

1. Boot from Debian netinst ISO
2. Choose "Install" (not graphical)
3. Follow installation wizard:
   - Language, location, keyboard
   - Configure network (DHCP recommended for template)
   - Hostname: `skyvyos` (temporary, will be changed)
   - Domain: Leave empty or your domain
   - Root password: Set temporary password
   - Create user account
   - Partition disk: Use entire disk, single partition
   
4. **Critical - Software selection**:
   - ✅ SSH server
   - ✅ Standard system utilities
   - ❌ **Uncheck everything else** (no desktop!)

5. Complete installation and reboot

## SkyvyOS Installation

### Step 4: Install SkyvyOS

1. Login to the VM (console or SSH)

2. Switch to root and install dependencies:
   ```bash
   su -
   apt update
   apt install -y wget curl sudo
   ```

3. Download SkyvyOS installer:
   ```bash
   wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
   chmod +x install-skyvyos.sh
   ```

4. Run installation:
   ```bash
   ./install-skyvyos.sh
   ```

   Installation takes 10-30 minutes depending on network speed.

5. **Before rebooting**, add your SSH key:
   ```bash
   # From your local machine
   ssh-copy-id root@VM_IP
   
   # Or manually:
   mkdir -p ~/.ssh
   nano ~/.ssh/authorized_keys
   # Paste your public key
   chmod 600 ~/.ssh/authorized_keys
   ```

6. Reboot:
   ```bash
   reboot
   ```

### Step 5: Post-Installation Verification

After reboot, verify installation:

```bash
# SSH into the VM
ssh root@VM_IP

# Verify SkyvyOS
skyvy-info
cat /etc/os-release

# Check services
sudo systemctl status nginx
sudo systemctl status docker
sudo ufw status
```

## Converting to Template

### Step 6: Prepare for Template

1. SSH into the VM

2. Run template preparation script:
   ```bash
   wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/prepare-vm-template.sh
   chmod +x prepare-vm-template.sh
   sudo ./prepare-vm-template.sh
   ```

   This script will:
   - Stop all services
   - Clean caches and temporary files
   - Remove SSH host keys (regenerated on clone)
   - Clear machine-id (unique per VM)
   - Clear logs and history
   - Install cloud-init for automation
   - Prepare for cloning

3. **Shutdown the VM**:
   ```bash
   sudo shutdown -h now
   ```

### Step 7: Convert to Template

The conversion process varies by platform:

#### KVM/QEMU
```bash
# Create template from existing VM
qemu-img convert -O qcow2 skyvyos.qcow2 skyvyos-template.qcow2

# Or use virt-sysprep
virt-sysprep -d skyvyos-vm

# Clone from template
virt-clone --original skyvyos-template --name web-server-01 --auto-clone
```

#### VMware
1. In vSphere/vCenter:
   - Right-click VM → Template → Convert to Template
   
2. In VMware Workstation/Fusion:
   - VM → Manage → Clone → Full Clone

#### VirtualBox
```bash
# Export as OVA
vboxmanage export skyvyos -o skyvyos-template.ova

# Clone VM
vboxmanage clonevm skyvyos --name web-server-01 --register
```

#### Hyper-V
```powershell
# Export VM
Export-VM -Name "SkyvyOS" -Path "C:\Templates\"

# Import and clone
Import-VM -Path "C:\Templates\SkyvyOS\Virtual Machines\*.vmcx" -Copy -GenerateNewId
```

## Deploying from Template

### Step 8: Clone/Deploy from Template

Choose your platform-specific method:

#### Generic Process
1. Clone the template VM
2. Give it a unique name (e.g., `web-server-01`)
3. Allocate resources (CPU, RAM, disk)
4. Configure network (static IP or DHCP)
5. Start the VM

#### First Boot
On first boot, the VM will:
- Generate new SSH host keys
- Create unique machine-id
- Run cloud-init (if configured)
- Be ready for use

### Step 9: Configure New VM

After booting:

```bash
# SSH into new VM
ssh root@NEW_VM_IP

# Verify uniqueness
cat /etc/machine-id
hostname
cat /etc/ssh/ssh_host_*.pub

# Set new hostname
sudo hostnamectl set-hostname web-server-01

# Configure as needed
```

## Cloud-Init Configuration

Cloud-init enables automated VM configuration. It's compatible with most cloud and virtualization platforms.

### Basic Cloud-Init Setup

Create a `user-data` file:

```yaml
#cloud-config
hostname: web-server-01
fqdn: web-server-01.example.com
manage_etc_hosts: true

users:
  - name: admin
    groups: sudo, docker
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-key-here

packages:
  - htop
  - vim

runcmd:
  - systemctl restart sshd
  - ufw allow from 192.168.1.0/24

timezone: Asia/Jakarta

power_state:
  mode: reboot
  condition: true
```

### Platform-Specific Cloud-Init

#### KVM/QEMU with cloud-localds
```bash
# Create cloud-init ISO
cloud-localds cloud-init.iso user-data

# Attach to VM
virsh attach-disk web-server-01 cloud-init.iso sdb --type cdrom
```

#### VMware
Use vmware-guestinfo provider or create ISO with cloud-init data

#### Cloud Platforms
Most cloud platforms (AWS, GCP, Azure) handle cloud-init automatically

### Cloud-Init Commands

Inside the VM:

```bash
# Check cloud-init status
cloud-init status

# View configuration
cloud-init query -a

# View logs
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# Re-run cloud-init (if needed)
sudo cloud-init clean
sudo cloud-init init
```

## Best Practices

### Template Management

1. **Version Control**:
   - Name templates with versions: `skyvyos-v1.0`, `skyvyos-v1.1`
   - Keep previous versions for rollback
   - Document changes between versions

2. **Regular Updates**:
   - Monthly: Update template with security patches
   - Quarterly: Review and optimize configuration
   - Recreate template after major updates

3. **Testing**:
   - Test new template versions before production
   - Verify all services start correctly
   - Check cloud-init functionality

### VM Deployment

1. **Naming Convention**:
   - Use descriptive names: `prod-web-01`, `dev-api-02`
   - Include environment: production, staging, development
   - Include purpose: web, db, app, cache

2. **Resource Allocation**:
   - Start conservative, scale up as needed
   - Monitor actual usage before adding resources
   - Use thin provisioning for disk to save space

3. **Network Configuration**:
   - Use static IPs for production servers
   - Configure DNS properly
   - Set up firewall rules

4. **Documentation**:
   - Document each deployed VM
   - Track what's running on which VM
   - Maintain inventory

### Security

1. **SSH Keys**:
   - Use unique SSH keys per VM or environment
   - Never reuse the same key everywhere
   - Disable root login in production

2. **Network Isolation**:
   - Use VLANs or network segments
   - Firewall between environments
   - Limit inter-VM communication

3. **Monitoring**:
   - Set up centralized logging
   - Monitor resource usage
   - Alert on security events

4. **Backups**:
   - Regular VM snapshots
   - Export important VMs
   - Test restore procedures

## Automation

### Scripted Deployment Example

```bash
#!/bin/bash
# deploy-vm.sh - Automated VM deployment script

VM_NAME="web-server-01"
TEMPLATE="skyvyos-template"
MEMORY=2048
CPUS=2
IP_ADDRESS="192.168.1.100"

# Platform-specific deployment commands here
# Example for KVM:
virt-clone \
  --original $TEMPLATE \
  --name $VM_NAME \
  --auto-clone

# Start VM
virsh start $VM_NAME

echo "VM $VM_NAME deployed successfully"
```

### Terraform Integration

```hcl
# Example for VMware vSphere
resource "vsphere_virtual_machine" "web_server" {
  name             = "web-server-01"
  folder           = "/VMs/Production"
  num_cpus         = 2
  memory           = 2048
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  
  disk {
    label            = "disk0"
    size             = 20
    thin_provisioned = true
  }
}
```

## Troubleshooting

### Clone Issues

**Problem**: Cloned VM won't boot or has network issues

**Solution**:
```bash
# Regenerate network interface IDs
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Regenerate machine-id
rm -f /etc/machine-id
systemd-machine-id-setup

# Regenerate SSH keys
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
```

### Cloud-Init Not Working

**Problem**: Configuration not applied

**Solution**:
```bash
# Check cloud-init status
cloud-init status --long

# View errors
sudo cat /var/log/cloud-init.log

# Force re-run
sudo cloud-init clean --logs
sudo reboot
```

### Duplicate SSH Keys

**Problem**: Multiple VMs have same SSH host keys

**Solution**:
- Ensure template preparation script was run before cloning
- Manually regenerate keys on cloned VMs
- Use cloud-init to regenerate automatically

## Advanced Topics

### Packer for Automated Template Building

```hcl
source "qemu" "skyvyos" {
  iso_url          = "debian-12-amd64-netinst.iso"
  iso_checksum     = "sha256:..."
  output_directory = "output"
  vm_name          = "skyvyos-template"
  memory           = 2048
  
  http_directory    = "http"
  boot_command      = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"
  ]
}

build {
  sources = ["source.qemu.skyvyos"]
  
  provisioner "shell" {
    scripts = [
      "scripts/install-skyvyos.sh",
      "scripts/prepare-vm-template.sh"
    ]
  }
}
```

### Mass Deployment

For deploying multiple VMs at once, use orchestration tools:
- Terraform (infrastructure as code)
- Ansible (configuration management)
- Vagrant (development environments)
- Cloud-specific tools (CloudFormation, ARM templates, etc.)

---

**SkyvyOS Server** is fully compatible with industry-standard virtualization platforms. Choose the one that fits your infrastructure!
