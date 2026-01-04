# 📖 Panduan Instalasi SkyvyOS Secure Server

Panduan ini menjelaskan langkah-langkah instalasi SkyvyOS Secure Server secara lengkap.

## 📋 Persyaratan Sistem

- **CPU**: 1 Core (minimal), 2 Core+ (rekomendasi)
- **RAM**: 512 MB (minimal), 2 GB+ (rekomendasi)
- **Disk**: 10 GB (minimal), 20 GB+ (rekomendasi)
- **Jaringan**: Koneksi internet diperlukan saat instalasi

---

## 🚀 Metode 1: Instalasi Otomatis (Direkomendasikan)

Metode ini paling mudah. Anda hanya perlu menginstall Debian 12 minimal, lalu jalankan script installer kami.

### Langkah 1: Install Debian 12 Minimal
1. Download **Debian 12 'netinst' ISO** dari website resmi Debian.
2. Install Debian seperti biasa pada server/VM Anda.
3. Saat pemilihan software (Software Selection):
   - **Hapus centang** pada "Debian desktop environment"
   - **Hapus centang** pada "GNOME" (atau lainnya)
   - **Pastikan tercentang**: "SSH server" dan "Standard system utilities"

### Langkah 2: Login ke Server
Login menggunakan user `root` atau user dengan akses `sudo`.

### Langkah 3: Download & Jalankan Installer
Copy dan paste perintah berikut ke terminal:

```bash
# 1. Update dan install git
sudo apt update
sudo apt install -y git

# 2. Clone repository SkyvyOS
git clone https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server.git
cd SkyvyOS-Secure-Server

# 3. Jalankan installer
sudo bash scripts/install-skyvyos.sh
```

### Langkah 4: Tunggu Proses
Script akan otomatis:
- Mengupdate sistem
- Menginstall Nginx, Docker, & bahasa pemrograman
- Mengkonfigurasi firewall & keamanan (Hardening)
- Memasang branding SkyvyOS

### Langkah 5: Reboot
Setelah selesai, restart server Anda:
```bash
sudo reboot
```

---

## 💿 Metode 2: Membuat file ISO Sendiri

Jika Anda ingin membuat file `.iso` siap pakai (misalnya untuk instalasi massal), gunakan cara ini.

### Langkah 1: Siapkan Sistem Build
Gunakan komputer dengan OS Debian 12 atau Ubuntu 22.04/24.04.

```bash
# Install tool yang dibutuhkan
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools genisoimage syslinux isolinux xorriso
```

### Langkah 2: Download Script
```bash
git clone https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server.git
cd SkyvyOS-Secure-Server
```

### Langkah 3: Mulai Build
```bash
sudo bash scripts/build-skyvyos-iso.sh
```

Proses ini memakan waktu 15-30 menit tergantung kecepatan internet.

### Langkah 4: Ambil File ISO
Setelah selesai, file ISO akan muncul di folder `build/`:
`SkyvyOS-Secure-Server-YYYYMMDD-HHMMSS.iso`

Anda bisa menggunakan file ini untuk boot dan install di server fisik atau Virtual Machine.

---

## 💻 Metode 3: Template Virtual Machine (Proxmox/VMware)

Jika Anda menggunakan Proxmox, kami menyediakan script untuk mengubah instalasi menjadi template.

1. Install SkyvyOS menggunakan **Metode 1** di dalam VM Proxmox.
2. Jangan lakukan konfigurasi spesifik user dulu.
3. Jalankan script persiapan template:

```bash
sudo bash scripts/prepare-proxmox-template.sh
```

4. Matikan VM dan convert menjadi Template di Proxmox.

---

## 🔧 Pasca Instalasi (Apa yang harus dilakukan selanjutnya?)

Setelah instalasi selesai, sistem sudah aman (hardened). Berikut beberapa hal yang perlu diketahui:

### 1. Login SSH
- **Root login dimatikan** secara default.
- **Login Password dimatikan**. Anda harus login menggunakan SSH Key.
- Jika Anda belum setup SSH Key, gunakan user biasa yang dibuat saat instalasi Debian.

### 2. Cek Status Sistem
Ketik perintah ini untuk melihat info server:
```bash
skyvyos-info
```

### 3. Cek Keamanan
Jalankan audit keamanan otomatis:
```bash
sudo skyvy-security-audit
```

### 4. Firewall (UFW)
Secara default semua port masuk **DIBLOKIR** kecuali SSH (22), HTTP (80), dan HTTPS (443).
Untuk membuka port lain (misal 8080):
```bash
sudo ufw allow 8080/tcp
```

---

## 🆘 Bantuan
Jika mengalami masalah, silakan buat Issue di GitHub:
https://github.com/MuhammadLutfiMuzakiiVY/SkyvyOS-Secure-Server/issues
