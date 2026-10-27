#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan skrip ini menggunakan sudo: sudo ./install.sh"
  exit 1
fi

echo "==> Menginstal dependensi (iw, zenity, tlp, powertop)..."
apt update && apt install -y iw zenity tlp powertop

echo "==> Menyalin berkas backend dan GUI ke /usr/local/bin/..."
cp power-backend.sh /usr/local/bin/power-backend.sh
cp power-control-gui.sh /usr/local/bin/power-control-gui.sh

chmod +x /usr/local/bin/power-backend.sh
chmod +x /usr/local/bin/power-control-gui.sh

echo "==> Mengatur hak akses sudoers tanpa password..."
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -n "$CURRENT_USER" ]; then
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/local/bin/power-backend.sh *" > /etc/sudoers.d/power-control
    chmod 440 /etc/sudoers.d/power-control
    echo "==> Izin sudoers berhasil diatur untuk user: $CURRENT_USER"
else
    echo "Peringatan: Gagal mendeteksi user aktif untuk konfigurasi sudoers."
fi

echo "==> Instalasi Selesai! Anda dapat menjalankan aplikasi melalui terminal dengan perintah:"
echo "    power-control-gui.sh (atau buat shortcut aplikasi desktop menunjuk ke file ini)"
