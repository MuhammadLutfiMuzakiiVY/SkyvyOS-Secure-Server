# SkyvyOS Secure Server - Custom ISO Build Guide

**Create Bootable Installation Media for SkyvyOS Secure Server**

## Overview

This guide covers **three methods** to create SkyvyOS installation media:

1. **Method 1: Preseed + Netinst** (Recommended) - Smallest, automated Debian netinst + SkyvyOS post-install
2. **Method 2: Live Build** (Advanced) - Full custom ISO with all packages pre-installed
3. **Method 3: Hybrid ISO** (Best of both) - Custom installer with network-free installation

## Method 1: Preseed + Netinst (Recommended)

**Advantages**:
- Smallest ISO size (~400 MB)
- Always gets latest packages
- Fully automated installation
- Easy to maintain

### Step 1: Download Debian Netinst

```bash
# Download latest Debian 12 (Bookworm) netinst
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.X.0-amd64-netinst.iso

# Verify checksum
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

### Step 2: Create Preseed Configuration

**File: preseed/skyvyos-preseed.cfg**

```bash
#### SkyvyOS Secure Server - Preseed Configuration
#### Fully automated Debian installation for SkyvyOS

### Localization
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

### Network configuration
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string skyvyos
d-i netcfg/get_domain string localdomain
d-i netcfg/wireless_wep string

### Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

### Account setup
# Skip root account creation (will use sudo)
d-i passwd/root-login boolean false

# Create admin user
d-i passwd/user-fullname string SkyvyOS Administrator
d-i passwd/username string admin
d-i passwd/user-password-crypted password $6$rounds=656000$SALT$HASH
# Generate with: mkpasswd -m sha-512 -R 656000

### Clock and time zone
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i clock-setup/ntp boolean true

### Partitioning
# Use entire disk with LVM
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

# Partitioning scheme
d-i partman-auto/choose_recipe select atomic
d-i partman-auto-lvm/guided_size string max

# Confirm partitioning
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

### Package selection
tasksel tasksel/first multiselect standard, ssh-server

# Individual packages
d-i pkgsel/include string \
    vim curl wget git htop tmux \
    ufw fail2ban \
    sudo \
    rsync \
    net-tools \
    apt-transport-https \
    ca-certificates \
    gnupg

# Upgrade packages after debootstrap
d-i pkgsel/upgrade select full-upgrade

# No automatic updates during install (we'll configure later)
d-i pkgsel/update-policy select none

### Boot loader
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

### Finishing up
d-i finish-install/reboot_in_progress note

### Post-installation script
d-i preseed/late_command string \
    in-target wget -O /tmp/skyvyos-install.sh https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh; \
    in-target chmod +x /tmp/skyvyos-install.sh; \
    in-target /tmp/skyvyos-install.sh --preseed; \
    in-target wget -O /tmp/master-hardening.sh https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/master-hardening.sh; \
    in-target chmod +x /tmp/master-hardening.sh; \
    in-target /tmp/master-hardening.sh --preseed
```

### Step 3: Inject Preseed into ISO

```bash
#!/bin/bash
# inject-preseed.sh - Inject preseed into Debian netinst ISO

set -e

ORIGINAL_ISO="debian-12.X.0-amd64-netinst.iso"
PRESEED_FILE="skyvyos-preseed.cfg"
OUTPUT_ISO="skyvyos-server-12.X.0-amd64.iso"

# Requirements
command -v genisoimage >/dev/null || { echo "Install genisoimage"; exit 1; }
command -v isohybrid >/dev/null || { echo "Install syslinux-utils"; exit 1; }

# Create working directory
WORK_DIR="iso_build"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Extract ISO
echo "[1/5] Extracting original ISO..."
7z x ../$ORIGINAL_ISO

# Copy preseed file
echo "[2/5] Adding preseed configuration..."
cp ../$PRESEED_FILE preseed.cfg

# Modify isolinux config for auto-install
echo "[3/5] Configuring auto-install..."
cat > isolinux/txt.cfg <<EOF
default skyvyos-auto
label skyvyos-auto
    menu label ^SkyvyOS Automated Installation
    kernel /install.amd/vmlinuz
    append auto=true priority=critical vga=788 initrd=/install.amd/initrd.gz preseed/file=/cdrom/preseed.cfg --- quiet
EOF

# Rebuild ISO
echo "[4/5] Building new ISO..."
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o ../$OUTPUT_ISO .

# Make hybrid (bootable from USB)
echo "[5/5] Making hybrid ISO..."
cd ..
isohybrid $OUTPUT_ISO

# Cleanup
rm -rf $WORK_DIR

echo "✓ SkyvyOS ISO created: $OUTPUT_ISO"
echo "✓ Write to USB: sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
```

## Method 2: Live Build (Full Custom ISO)

**Advantages**:
- Complete control over everything
- Can work offline
- Pre-installed packages

**Disadvantages**:
- Larger ISO size (1-2 GB+)
- More complex to maintain

### Build Script

```bash
#!/bin/bash
# build-skyvyos-iso.sh - Build complete SkyvyOS custom ISO

set -e

# Install live-build
apt-get update
apt-get install -y live-build

# Create build directory
mkdir -p skyvyos-live
cd skyvyos-live

# Configure live-build
lb config \
    --distribution bookworm \
    --debian-installer live \
    --archive-areas "main contrib non-free-firmware" \
    --apt-indices false \
    --apt-recommends false \
    --binary-images iso-hybrid \
    --mode debian \
    --system live \
    --bootappend-live "\
        boot=live \
        components \
        quiet \
        splash" \
    --bootloader grub-efi \
    --linux-packages linux-image \
    --security true \
    --updates true

# Add packages
cat > config/package-lists/skyvyos.list.chroot <<EOF
# SkyvyOS Base Packages

# System
systemd
sudo
vim
tmux
htop

# Security
openssh-server
ufw
fail2ban
auditd
aide

# Network
curl
wget
rsync
net-tools

# Monitoring
sysstat
logwatch

# Web server
nginx

# Tools
git
tree
ncdu
EOF

# Add custom files
mkdir -p config/includes.chroot/etc/skyvyos
cp -r ../config/* config/includes.chroot/etc/skyvyos/
cp -r ../scripts/* config/includes.chroot/usr/local/bin/
cp -r ../branding/* config/includes.chroot/etc/

# Add post-installation hook
cat > config/hooks/live/9999-skyvyos-hardening.hook.chroot <<'EOF'
#!/bin/bash
# SkyvyOS post-install hardening

# Run master hardening script
/usr/local/bin/master-hardening.sh --build

# Setup SkyvyOS branding
cp /etc/skyvyos-os-release /etc/os-release
cp /etc/skyvyos-motd /etc/motd
EOF

chmod +x config/hooks/live/9999-skyvyos-hardening.hook.chroot

# Build ISO
lb build

# Result
echo "✓ SkyvyOS Live ISO built!"
ls -lh *.iso
```

## Method 3: Creating Bootable USB

### Linux

```bash
# Find USB device
lsblk

# Write ISO to USB (replace /dev/sdX with your USB device!)
sudo dd if=skyvyos-server.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Or use more user-friendly tool
sudo install -y pv
pv skyvyos-server.iso | sudo dd of=/dev/sdX bs=4M oflag=sync
```

### Windows

**Using Rufus**:
1. Download Rufus: https://rufus.ie/
2. Select SkyvyOS ISO
3. Partition scheme: MBR or GPT (depends on target system)
4. Target system: BIOS or UEFI
5. Click START

**Using Etcher**:
1. Download balenaEtcher
2. Select ISO
3. Select USB drive
4. Flash!

### macOS

```bash
# Find USB device
diskutil list

# Unmount (not eject!)
diskutil unmountDisk /dev/diskN

# Write ISO
sudo dd if=skyvyos-server.iso of=/dev/rdiskN bs=1m

# Eject
diskutil eject /dev/diskN
```

## Automated Build Pipeline

**File: build-pipeline.sh**

```bash
#!/bin/bash
# SkyvyOS ISO Build Pipeline
# Automated ISO creation with versioning

set -eo pipefail

VERSION=${1:-"1.0.0"}
BUILD_DATE=$(date +%Y%m%d)
ISO_NAME="skyvyos-secure-server-${VERSION}-${BUILD_DATE}-amd64.iso"

echo "Building SkyvyOS ISO version $VERSION"
echo "Build date: $BUILD_DATE"

# Choose build method
read -p "Build method? [1=Preseed, 2=Live, 3=Both]: " METHOD

case $METHOD in
    1)
        echo "Building with preseed method..."
        ./inject-preseed.sh
        mv skyvyos-*.iso "$ISO_NAME"
        ;;
    2)
        echo "Building with live-build..."
        ./build-skyvyos-iso.sh
        mv live-image-amd64.hybrid.iso "$ISO_NAME"
        ;;
    3)
        echo "Building both..."
        ./inject-preseed.sh
        ./build-skyvyos-iso.sh
        ;;
esac

# Generate checksums
sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"
md5sum "$ISO_NAME" > "${ISO_NAME}.md5"

# Create info file
cat > "${ISO_NAME}.info" <<EOF
SkyvyOS Secure Server
Version: $VERSION
Build Date: $BUILD_DATE
ISO Size: $(du -h "$ISO_NAME" | cut -f1)
SHA256: $(cat ${ISO_NAME}.sha256 | cut -d' ' -f1)
MD5: $(cat ${ISO_NAME}.md5 | cut -d' ' -f1)

Default Credentials:
Username: admin
Password: (set during installation or use preseed)

Documentation: https://github.com/YOUR_REPO/skyvyos-server
EOF

echo "✓ Build complete!"
echo "✓ ISO: $ISO_NAME"
echo "✓ Checksums generated"
cat "${ISO_NAME}.info"
```

## Testing the ISO

### VirtualBox Test

```bash
# Create VM
VBoxManage createvm --name "SkyvyOS-Test" --ostype Debian_64 --register

# Configure VM
VBoxManage modifyvm "SkyvyOS-Test" \
    --memory 2048 \
    --cpus 2 \
    --nic1 nat \
    --boot1 dvd \
    --boot2 disk

# Create disk
VBoxManage createhd --filename ~/VirtualBox\ VMs/SkyvyOS-Test/disk.vdi --size 20480

# Attach storage
VBoxManage storagectl "SkyvyOS-Test" --name "SATA" --add sata
VBoxManage storageattach "SkyvyOS-Test" --storagectl "SATA" --port 0 --device 0 --type hdd --medium ~/VirtualBox\ VMs/SkyvyOS-Test/disk.vdi
VBoxManage storageattach "SkyvyOS-Test" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium skyvyos-server.iso

# Start VM
VBoxManage startvm "SkyvyOS-Test"
```

### QEMU/KVM Test

```bash
qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom skyvyos-server.iso \
    -boot d \
    -hda test-disk.qcow2 \
    -enable-kvm
```

## Distribution

### GitHub Releases

```bash
# Create release with ISO
gh release create v1.0.0 \
    skyvyos-*.iso \
    skyvyos-*.sha256 \
    skyvyos-*.md5 \
    skyvyos-*.info \
    --title "SkyvyOS Secure Server v1.0.0" \
    --notes "Security-hardened Debian-based server OS"
```

### Hosting

- **GitHub Releases**: Free, reliable
- **SourceForge**: Traditional distribution
- **Custom Server**: Direct download

## Troubleshooting

### ISO won't boot
- Check BIOS/UEFI settings
- Verify ISO integrity (checksums)
- Try different USB writing tool
- Check secure boot settings

### Installation fails
- Check network connection (for netinst)
- Review preseed configuration
- Check disk space
- View installation logs (Alt+F4 during install)

### Post-install issues
- Check `/var/log/installer/syslog`
- Verify hardening scripts ran
- Check network configuration

---

**Next Steps**: Build ISO → Test in VM → Deploy to production

**Note**: Untuk production deployment, selalu test ISO di VM terlebih dahulu!
