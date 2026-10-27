# Linux Advanced Power Management Toolkit
Toolkit manajemen daya modular berbasis terminal dan Zenity GUI khusus untuk Linux (dirancang dan diuji pada Linux Mint & Ubuntu).

## Fitur Utama:
- **AMD P-State EPP & Governor Control**: Beralih otomatis antara `power`/`powersave` dan `performance`.
- **CPU Boost Control**: Mengaktifkan atau menonaktifkan boost core CPU.
- **PCIe ASPM Powersave**: Menurunkan konsumsi daya jalur PCIe ke mode `powersupersave`.
- **Smart Screen Brightness Control**: Mencatat kecerahan awal dan memangkas secara cerdas ke 40% (hanya jika posisi awal lebih terang dari 40%, sehingga tidak menaikkan kecerahan di ruangan gelap).
- **Audio & Wi-Fi Power Saving**: Mengaktifkan penghematan daya chip audio dan modul Wi-Fi secara dinamis.
- **State Restoration**: Mengembalikan konfigurasi Bluetooth, Wi-Fi, TLP, Audio, dan Kecemerlangan Layar ke kondisi semula saat mode `OFF` diaktifkan.

## Cara Instalasi di PC/Laptop Lain:
1. Ekstrak arsip ini.
2. Buka terminal di dalam folder hasil ekstraksi.
3. Jalankan perintah instalasi otomatis:
   ```bash
   sudo ./install.sh
   ```
4. Buat shortcut aplikasi desktop yang mengarah ke `/usr/local/bin/power-control-gui.sh` untuk akses instan via GUI.
