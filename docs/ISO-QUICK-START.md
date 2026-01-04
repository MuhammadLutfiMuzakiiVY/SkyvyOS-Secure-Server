# SkyvyOS Secure Server - Quick Start ISO Build

**Build Your Own Bootable SkyvyOS Installation Media**

## Prerequisites

```bash
# On Ubuntu/Debian build machine
sudo apt-get install -y \
    wget \
    genisoimage \
    syslinux-utils \
    p7zip-full \
    qemu-system-x86
```

## Quick Build (5 minutes)

```bash
# 1. Navigate to scripts directory
cd "SkyvyOS Server/scripts"

# 2. Run ISO builder
sudo ./build-skyvyos-iso.sh 1.0.0

# 3. ISO will be created in ../build/ directory
# Output: skyvyos-secure-server-1.0.0-YYYYMMDD-amd64.iso
```

## Test in VM

```bash
cd ../build

# Quick test with QEMU
qemu-system-x86_64 \
    -m 2048 \
    -cdrom skyvyos-*.iso \
    -boot d
```

## Write to USB

```bash
# Use helper script (Linux only)
sudo ./write-to-usb.sh skyvyos-*.iso

# Or manually
sudo dd if=skyvyos-*.iso of=/dev/sdX bs=4M status=progress
```

## Installation Process

1. **Boot from USB/CD**
   - Select "SkyvyOS Secure Server - Automated Installation"

2. **Automated Installation (15-30 min)**
   - Network configuration (DHCP)
   - Disk partitioning (entire disk)
   - Package installation
   - User creation (admin)
   - GRUB installation

3. **Post-Installation**
   ```bash
   # After reboot, login as admin
   ssh admin@your-server-ip
   
   # Run hardening scripts
   cd /root/skyvyos-install
   sudo ./install-skyvyos.sh
   sudo ./security-hardening.sh
   ```

4. **Final Steps**
   - Add SSH public key: `~/.ssh/authorized_keys`
   - Reboot
   - Done! SkyvyOS Secure Server ready

## Customization

### Change Default Password

Edit `preseed/skyvyos-preseed.cfg`:

```bash
# Generate new password hash
mkpasswd -m sha-512 -R 656000

# Replace in preseed file
d-i passwd/user-password-crypted password $6$...
```

### Add Custom Packages

Edit `preseed/skyvyos-preseed.cfg`:

```bash
d-i pkgsel/include string \
    your-package-1 \
    your-package-2
```

### Change Hostname

Edit `preseed/skyvyos-preseed.cfg`:

```bash
d-i netcfg/get_hostname string your-hostname
```

## Distribution

```bash
# Upload to GitHub Releases
gh release create v1.0.0 \
    build/skyvyos-*.iso \
    build/skyvyos-*.sha256 \
    build/skyvyos-*.info \
    --title "SkyvyOS Secure Server v1.0.0"
```

## Troubleshooting

**ISO build fails**:
```bash
# Check requirements
sudo apt-get install genisoimage syslinux-utils p7zip-full

# Check permissions
sudo chown -R $USER:$USER ../build
```

**Boot fails**:
- Disable Secure Boot in BIOS/UEFI
- Verify USB write with: `sudo fdisk -l /dev/sdX`
- Try different USB port/stick

**Installation hangs**:
- Check network connection (needed for packages)
- Check disk space (minimum 5 GB)
- Review logs: Alt+F4 during installation

---

**Ready to deploy!** One ISO, automated installation, production security hardening.
