#!/bin/bash

set -e  # Hentikan eksekusi jika terjadi error

# Update paket dan install dependencies
apt update && apt upgrade -y
apt install -y ccze curl tcpdump net-tools docker.io xfce4 xfce4-goodies \
               xorg dbus-x11 x11-xserver-utils xrdp ufw

# Konfigurasi sesi XFCE4 untuk XRDP
echo 'unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
xfce4-session' > ~/.xsession
chmod +x ~/.xsession

# Install ulang XRDP (jika perlu)
apt install --reinstall xrdp -y

# Download dan install UpRock Mining
wget -O uprock.deb https://app-download.uprock.com/UpRock-Mining-v0.0.8.deb
apt install ./uprock.deb -y
rm -f uprock.deb

# Membersihkan paket yang tidak diperlukan
apt autoremove -y

# Konfigurasi firewall
ufw allow 3389/tcp  # Izinkan XRDP
ufw allow OpenSSH    # Pastikan SSH tetap bisa diakses

# Aktifkan UFW hanya jika SSH sudah diizinkan
if ! ufw status | grep -q "22/tcp"; then
    echo "Menambahkan aturan firewall untuk SSH..."
    ufw allow 22/tcp
fi

ufw enable

# Pastikan direktori xrdp ada
mkdir -p /etc/xrdp

# Konfigurasi startwm.sh untuk XRDP
echo '#!/bin/sh
startxfce4' > /etc/xrdp/startwm.sh
chmod +x /etc/xrdp/startwm.sh

# Nonaktifkan mode sleep agar sistem tetap aktif
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Konfigurasi swapfile
fallocate -l 4G /swapfile 
chmod 600 /swapfile 
mkswap /swapfile 
swapon /swapfile 
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Restart layanan XRDP
systemctl restart xrdp

echo "Setup selesai. Anda bisa terhubung ke XRDP di port 3389."
echo "Akses SSH tetap tersedia di port 22."
