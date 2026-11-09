#!/usr/bin/env bash
# El script se detiene si hay errores
set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando adminpc "
echo "########################################"

apt-get update -y
apt-get install -y curl nmap tcpdump wget iputils-ping

# Usuario administrador (en Debian el grupo de administradores es "sudo", no "wheel")
echo "=> Creamos usuario administrador..."
id admin_AUT >/dev/null 2>&1 || useradd -m -s /bin/bash admin_AUT
usermod -aG sudo admin_AUT
echo "admin_AUT ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin_AUT
chmod 440 /etc/sudoers.d/admin_AUT

# Claves SSH inyectadas por Vagrant en /tmp
echo "=> Importamos claves SSH"
mkdir -p /home/admin_AUT/.ssh

# 1. Convertir de UTF-16LE a UTF-8 si viene en formato ancho desde Windows
if file /tmp/id_ed25519 | grep -q "UTF-16"; then
    iconv -f UTF-16LE -t UTF-8 /tmp/id_ed25519 > /home/admin_AUT/.ssh/id_ed25519
    iconv -f UTF-16LE -t UTF-8 /tmp/id_ed25519.pub > /home/admin_AUT/.ssh/id_ed25519.pub
else
    cp /tmp/id_ed25519 /home/admin_AUT/.ssh/id_ed25519
    cp /tmp/id_ed25519.pub /home/admin_AUT/.ssh/id_ed25519.pub
fi

# 2. Eliminar finales de línea CRLF (\r)
sed -i 's/\r$//' /home/admin_AUT/.ssh/id_ed25519 /home/admin_AUT/.ssh/id_ed25519.pub
# 3. Eliminar la marca BOM (UTF-8 con BOM que añade Windows y rompe libcrypto)
sed -i '1s/^\xef\xbb\xbf//' /home/admin_AUT/.ssh/id_ed25519 /home/admin_AUT/.ssh/id_ed25519.pub

chown -R admin_AUT:admin_AUT /home/admin_AUT/.ssh
chmod 700 /home/admin_AUT/.ssh
chmod 600 /home/admin_AUT/.ssh/id_ed25519
chmod 644 /home/admin_AUT/.ssh/id_ed25519.pub

# Evitar ruta por defecto por eth0 (requerido para Debian 13)
grep -q '^interface eth0' /etc/dhcpcd.conf || cat >> /etc/dhcpcd.conf <<'EOF'
interface eth0
nogateway
EOF

echo "------ FIN ------"