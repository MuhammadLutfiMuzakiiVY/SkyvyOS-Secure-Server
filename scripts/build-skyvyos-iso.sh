#!/bin/bash

################################################################################
# SkyvyOS Secure Server - Automated ISO Builder
#
# This script automates the creation of a bootable SkyvyOS installation ISO
# using Debian netinst + preseed configuration
#
# Usage: sudo ./build-skyvyos-iso.sh [version]
# Example: sudo ./build-skyvyos-iso.sh 1.0.0
################################################################################

set -euo pipefail

# Configuration
VERSION="${1:-1.0.0}"
BUILD_DATE=$(date +%Y%m%d)
DEBIAN_VERSION="12.4.0"
ARCH="amd64"

# File names
DEBIAN_ISO="debian-${DEBIAN_VERSION}-${ARCH}-netinst.iso"
DEBIAN_URL="https://cdimage.debian.org/debian-cd/current/${ARCH}/iso-cd/${DEBIAN_ISO}"
OUTPUT_ISO="skyvyos-secure-server-${VERSION}-${DEBIAN_VERSION}-${ARCH}-${BUILD_DATE}.iso"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/../build"
ISO_EXTRACT_DIR="${BUILD_DIR}/iso_extract"
PRESEED_DIR="${SCRIPT_DIR}/../preseed"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_step() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[ℹ] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[⚠] $1${NC}"
}

check_requirements() {
    print_step "Checking requirements..."
    
    local missing_tools=()
    
    command -v wget >/dev/null || missing_tools+=("wget")
    command -v genisoimage >/dev/null || missing_tools+=("genisoimage")
    command -v isohybrid >/dev/null || missing_tools+=("syslinux-utils")
    command -v 7z >/dev/null || missing_tools+=("p7zip-full")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install with: sudo apt-get install ${missing_tools[*]}"
        exit 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

cleanup() {
    if [ -d "$ISO_EXTRACT_DIR" ]; then
        rm -rf "$ISO_EXTRACT_DIR"
    fi
}

download_debian_iso() {
    print_step "Downloading Debian netinst ISO..."
    
    cd "$BUILD_DIR"
    
    if [ -f "$DEBIAN_ISO" ]; then
        print_info "Debian ISO already exists, skipping download"
    else
        wget -c "$DEBIAN_URL"
        
        # Download and verify checksum
        wget -q "https://cdimage.debian.org/debian-cd/current/${ARCH}/iso-cd/SHA256SUMS"
        
        if sha256sum -c SHA256SUMS 2>&1 | grep -q "$DEBIAN_ISO: OK"; then
            print_step "Checksum verified"
        else
            print_error "Checksum verification failed!"
            exit 1
        fi
    fi
}

extract_iso() {
    print_step "Extracting Debian ISO..."
    
    mkdir -p "$ISO_EXTRACT_DIR"
    cd "$ISO_EXTRACT_DIR"
    
    7z x "${BUILD_DIR}/${DEBIAN_ISO}" > /dev/null
}

inject_preseed() {
    print_step "Injecting SkyvyOS preseed configuration..."
    
    # Copy preseed file
    cp "${PRESEED_DIR}/skyvyos-preseed.cfg" "${ISO_EXTRACT_DIR}/preseed.cfg"
    
    # Modify boot configuration for auto-install
    cat > "${ISO_EXTRACT_DIR}/isolinux/txt.cfg" <<'EOF'
default skyvyos-auto
label skyvyos-auto
    menu label ^SkyvyOS Secure Server - Automated Installation
    kernel /install.amd/vmlinuz
    append auto=true priority=critical vga=788 initrd=/install.amd/initrd.gz preseed/file=/cdrom/preseed.cfg locale=en_US.UTF-8 keyboard-configuration/xkb-keymap=us --- quiet

label install
    menu label ^Debian Standard Installation
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/initrd.gz --- quiet
EOF

    # Update GRUB config for UEFI boot
    if [ -f "${ISO_EXTRACT_DIR}/boot/grub/grub.cfg" ]; then
        sed -i '1i menuentry "SkyvyOS Secure Server - Automated Installation" {\n    set background_color=black\n    linux    /install.amd/vmlinuz auto=true priority=critical preseed/file=/cdrom/preseed.cfg --- quiet\n    initrd   /install.amd/initrd.gz\n}' "${ISO_EXTRACT_DIR}/boot/grub/grub.cfg"
    fi
    
    # Add SkyvyOS branding
    cat > "${ISO_EXTRACT_DIR}/skyvyos-info.txt" <<EOF
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     ███████╗██╗  ██╗██╗   ██╗██╗   ██╗██╗   ██╗         ║
║     ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║   ██║╚██╗ ██╔╝         ║
║     ███████╗█████╔╝  ╚████╔╝ ██║   ██║ ╚████╔╝          ║
║     ╚════██║██╔═██╗   ╚██╔╝  ╚██╗ ██╔╝  ╚██╔╝           ║
║     ███████║██║  ██╗   ██║    ╚████╔╝    ██║            ║
║     ╚══════╝╚═╝  ╚═╝   ╚═╝     ╚═══╝     ╚═╝            ║
║                                                           ║
║           SkyvyOS Secure Server ${VERSION}                      ║
║       Enterprise Security-Hardened Debian OS              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Build Date: ${BUILD_DATE}
Base: Debian ${DEBIAN_VERSION}
Architecture: ${ARCH}

Features:
- Security-hardened by default
- Minimal attack surface
- Enterprise-grade access control
- Automated security updates
- Comprehensive audit logging
- Production-ready 24/7

Default Installation:
- Automated via preseed configuration
- User: admin (set password during install)
- SSH: Key-based authentication only
- Firewall: Enabled with strict rules

Documentation:
https://github.com/YOUR_REPO/skyvyos-server

License: MIT
EOF
}

rebuild_iso() {
    print_step "Building SkyvyOS ISO..."
    
    cd "$ISO_EXTRACT_DIR"
    
    # Update md5sum for files
    find . -type f -not -name md5sum.txt -not -path './isolinux/*' -exec md5sum {} \; > md5sum.txt
    
    # Build ISO
    genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -o "${BUILD_DIR}/${OUTPUT_ISO}" . > /dev/null 2>&1
    
    # Make hybrid (USB bootable)
    cd "$BUILD_DIR"
    isohybrid --uefi "$OUTPUT_ISO"
    
    print_step "ISO built successfully: $OUTPUT_ISO"
}

generate_checksums() {
    print_step "Generating checksums..."
    
    cd "$BUILD_DIR"
    
    sha256sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.sha256"
    md5sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.md5"
    
    print_info "SHA256: $(cat ${OUTPUT_ISO}.sha256 | cut -d' ' -f1)"
    print_info "MD5: $(cat ${OUTPUT_ISO}.md5 | cut -d' ' -f1)"
}

create_info_file() {
    print_step "Creating info file..."
    
    cd "$BUILD_DIR"
    
    cat > "${OUTPUT_ISO}.info" <<EOF
═══════════════════════════════════════════════════════════
          SkyvyOS Secure Server Installation Media
═══════════════════════════════════════════════════════════

Version: ${VERSION}
Build Date: ${BUILD_DATE}
Base: Debian ${DEBIAN_VERSION}
Architecture: ${ARCH}

ISO Information:
- File: ${OUTPUT_ISO}
- Size: $(du -h "${OUTPUT_ISO}" | cut -f1)
- SHA256: $(cat ${OUTPUT_ISO}.sha256 | cut -d' ' -f1)
- MD5: $(cat ${OUTPUT_ISO}.md5 | cut -d' ' -f1)

Installation:
- Automated installation via preseed
- Default user: admin (password set during install)
- Network required for package downloads
- Estimated time: 15-30 minutes

Write to USB:
  Linux:   sudo dd if=${OUTPUT_ISO} of=/dev/sdX bs=4M status=progress
  Windows: Use Rufus or Etcher
  macOS:   sudo dd if=${OUTPUT_ISO} of=/dev/rdiskN bs=1m

Boot:
- BIOS/Legacy: Supported
- UEFI: Supported
- Secure Boot: Disabled recommended

Documentation:
  https://github.com/YOUR_REPO/skyvyos-server/docs

Support:
  GitHub Issues: https://github.com/YOUR_REPO/skyvyos-server/issues

═══════════════════════════════════════════════════════════
EOF

    cat "${OUTPUT_ISO}.info"
}

create_usb_script() {
    print_step "Creating USB write helper script..."
    
    cat > "${BUILD_DIR}/write-to-usb.sh" <<'EOFSCRIPT'
#!/bin/bash
# Helper script to write SkyvyOS ISO to USB

set -e

ISO_FILE="$1"

if [ -z "$ISO_FILE" ]; then
    echo "Usage: sudo $0 <iso-file>"
    exit 1
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found: $ISO_FILE"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0 $ISO_FILE"
    exit 1
fi

echo "Available USB devices:"
lsblk -d -n -o NAME,SIZE,MODEL | grep -E "sd[a-z]"

echo ""
read -p "Enter USB device (e.g., sdb): " DEVICE

if [ -z "$DEVICE" ]; then
    echo "No device selected"
    exit 1
fi

DEVICE="/dev/$DEVICE"

if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a block device"
    exit 1
fi

echo "WARNING: This will ERASE all data on $DEVICE"
echo "ISO: $ISO_FILE"
echo "Device: $DEVICE"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted"
    exit 1
fi

echo "Writing ISO to $DEVICE..."
if command -v pv >/dev/null; then
    pv "$ISO_FILE" | dd of="$DEVICE" bs=4M oflag=sync status=none
else
    dd if="$ISO_FILE" of="$DEVICE" bs=4M status=progress oflag=sync
fi

sync

echo "✓ Done! USB is ready to boot."
echo "✓ Safely eject: sudo eject $DEVICE"
EOFSCRIPT

    chmod +x "${BUILD_DIR}/write-to-usb.sh"
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║       SkyvyOS Secure Server - ISO Builder                ║
║    Enterprise Security-Hardened Debian Distribution      ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_info "Building SkyvyOS ${VERSION}"
    print_info "Build date: ${BUILD_DATE}"
    print_info "Base: Debian ${DEBIAN_VERSION}"
    
    # Setup
    check_requirements
    mkdir -p "$BUILD_DIR"
    trap cleanup EXIT
    
    # Build process
    download_debian_iso
    extract_iso
    inject_preseed
    rebuild_iso
    generate_checksums
    create_info_file
    create_usb_script
    
    # Cleanup
    cleanup
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           SkyvyOS ISO BUILD SUCCESSFUL!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Output files in: ${BUILD_DIR}/${NC}"
    echo -e "  • ${OUTPUT_ISO}"
    echo -e "  • ${OUTPUT_ISO}.sha256"
    echo -e "  • ${OUTPUT_ISO}.md5"
    echo -e "  • ${OUTPUT_ISO}.info"
    echo -e "  • write-to-usb.sh (helper script)"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Test ISO in VM: qemu-system-x86_64 -m 2048 -cdrom ${BUILD_DIR}/${OUTPUT_ISO}"
    echo "  2. Write to USB: sudo ${BUILD_DIR}/write-to-usb.sh ${BUILD_DIR}/${OUTPUT_ISO}"
    echo "  3. Boot and install!"
    echo ""
}

main "$@"
