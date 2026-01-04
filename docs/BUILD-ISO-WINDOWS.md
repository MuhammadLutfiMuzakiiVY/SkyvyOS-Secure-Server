# SkyvyOS ISO Build - Step by Step Guide (Windows)

**Build SkyvyOS Bootable ISO di Windows menggunakan WSL**

## Persiapan (One-time setup)

### Step 1: Install WSL Ubuntu

```powershell
# Di PowerShell (Run as Administrator)
wsl --install -d Ubuntu

# Restart computer jika diminta
# Setelah restart, buka Ubuntu dari Start Menu
```

### Step 2: Setup Build Environment di WSL

```bash
# Di WSL Ubuntu terminal
sudo apt update
sudo apt install -y \
    wget \
    genisoimage \
    syslinux-utils \
    p7zip-full \
    isolinux

# Konfirmasi instalasi
which genisoimage  # Should show /usr/bin/genisoimage
```

## Build ISO (Every time)

### Step 3: Navigate ke Project

```bash
# Di WSL, akses folder Windows
cd /mnt/c/Users/muham/OneDrive/Documents/SkyvyOS\ Server

# Buat folder build kalau belum ada
mkdir -p build
```

### Step 4: Run Build Script

```bash
# Masuk ke folder scripts
cd scripts

# Beri permission execute
chmod +x build-skyvyos-iso.sh

# BUILD ISO! (butuh ~10-15 menit)
sudo ./build-skyvyos-iso.sh 1.0.0
```

**Output yang diharapkan:**
```
[✓] Checking requirements...
[✓] Downloading Debian netinst ISO...  (~400MB, 5-10 min)
[✓] Checksum verified
[✓] Extracting Debian ISO...
[✓] Injecting SkyvyOS preseed configuration...
[✓] Building SkyvyOS ISO...
[✓] ISO built successfully
[✓] Generating checksums...

═══════════════════════════════════════════════════════════
          SkyvyOS ISO BUILD SUCCESSFUL!
═══════════════════════════════════════════════════════════

Output files in: /mnt/c/Users/muham/OneDrive/Documents/SkyvyOS Server/build/
  • skyvyos-secure-server-1.0.0-12.4.0-amd64-20260104.iso
  • skyvyos-secure-server-1.0.0-12.4.0-amd64-20260104.iso.sha256
  • skyvyos-secure-server-1.0.0-12.4.0-amd64-20260104.iso.md5
  • skyvyos-secure-server-1.0.0-12.4.0-amd64-20260104.iso.info
  • write-to-usb.sh (helper script)
```

### Step 5: Verify ISO File

```bash
# Check file exists
ls -lh ../build/*.iso

# Should show something like:
# -rw-r--r-- 1 root root 450M Jan 4 19:00 skyvyos-secure-server-1.0.0-...iso
```

File ISO sekarang ada di:
```
C:\Users\muham\OneDrive\Documents\SkyvyOS Server\build\skyvyos-*.iso
```

## Gunakan ISO

### A. Bootable USB untuk Laptop Fisik

**Windows (Rufus):**
1. Download Rufus: https://rufus.ie/
2. Pilih USB stick (min 2GB)
3. SELECT: `skyvyos-*.iso`
4. Partition scheme: **MBR** (untuk legacy BIOS) atau **GPT** (untuk UEFI)
5. Click **START**
6. Done! USB bootable ready

**Windows (Etcher):**
1. Download Etcher: https://www.balena.io/etcher/
2. Flash from file → pilih ISO
3. Select USB drive
4. Flash!

### B. VMware

1. Buka VMware Workstation/Player
2. Create New Virtual Machine
3. **Installer disc image file (iso):** Browse → pilih `skyvyos-*.iso`
4. Guest OS: Linux → Debian 12 64-bit
5. Disk: 20 GB minimum
6. Memory: 2048 MB (2GB)
7. Finish → Power On
8. Installation otomatis berjalan!

### C. VirtualBox

1. Buka VirtualBox
2. New → Name: SkyvyOS, Type: Linux, Version: Debian (64-bit)
3. Memory: 2048 MB
4. Create virtual hard disk: 20 GB
5. Settings → Storage → Controller IDE → Add CD/DVD
6. Choose disk → pilih `skyvyos-*.iso`
7. Start → Installation otomatis berjalan!

## Test Installation Flow

Setelah boot dari ISO:

```
1. Boot screen muncul
   → Pilih: "SkyvyOS Secure Server - Automated Installation"

2. [AUTOMATED] Network configuration (DHCP)
   → Tunggu 1-2 menit

3. [AUTOMATED] Disk partitioning
   → Seluruh disk, LVM

4. [AUTOMATED] Package installation
   → Download packages from mirror (~10-20 min)

5. [MANUAL] Set password untuk user 'admin'
   → Masukkan password yang kuat!

6. [AUTOMATED] GRUB installation
   → Boot loader installed

7. [AUTOMATED] Reboot
   → Remove ISO/USB

8. First boot: Login sebagai 'admin'
   → SSH: ssh admin@<ip-address>

9. Run hardening scripts:
   cd /root/skyvyos-install
   sudo ./install-skyvyos.sh
   sudo ./security-hardening.sh

10. Add SSH key:
    mkdir -p ~/.ssh
    nano ~/.ssh/authorized_keys
    (paste your public key)

11. Reboot final:
    sudo reboot

12. ✓ SkyvyOS Secure Server READY!
```

## Troubleshooting

### Build gagal - "command not found"
```bash
# Install ulang tools
sudo apt install -y genisoimage syslinux-utils p7zip-full
```

### Download Debian ISO lambat
```bash
# Edit script, ganti mirror
# Line ~55 di build-skyvyos-iso.sh
DEBIAN_URL="https://mirror.poliwangi.ac.id/debian-cd/current/amd64/iso-cd/${DEBIAN_ISO}"
# Or manual download, lalu simpan di build/
```

### ISO tidak bootable
- Pastikan write USB dengan Rufus/Etcher (bukan copy paste biasa)
- Untuk laptop lama: Pilih MBR partition scheme
- Untuk laptop baru: Pilih GPT partition scheme
- Disable Secure Boot di BIOS jika perlu

### VMware/VirtualBox tidak detect ISO
- Pastikan file ISO tidak corrupt (check sha256sum)
- Pastikan ukuran file >300MB
- Coba mount manual di Settings

## Size Reference

- **ISO download**: ~400 MB (Debian netinst)
- **Final ISO**: ~450 MB
- **After install**: ~2 GB (dengan semua packages)
- **Recommended disk**: 20 GB (untuk logs, apps)

## Alternative: Skip Build, Use Debian + Scripts

Kalau tidak mau build ISO, bisa juga:

1. Download Debian 12 netinst langsung: https://www.debian.org/CD/netinst/
2. Install Debian minimal (SSH server only)
3. Login, download scripts:
   ```bash
   wget https://raw.githubusercontent.com/YOUR_REPO/skyvyos-server/main/scripts/install-skyvyos.sh
   chmod +x install-skyvyos.sh
   sudo ./install-skyvyos.sh
   ```

Tapi dengan ISO custom, prosesnya lebih smooth dan automated!

---

**Selamat mencoba! Kalau ada error saat build, share error message-nya.**
