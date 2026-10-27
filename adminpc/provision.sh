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
cp /tmp/id_ed25519 /home/admin_AUT/.ssh/id_ed25519
cp /tmp/id_ed25519.pub /home/admin_AUT/.ssh/id_ed25519.pub

# Por si las claves vienen de Windows con finales de línea CRLF (¡Corregido en una sola línea!)
sed -i 's/\r$//' /home/admin_AUT/.ssh/id_ed25519 /home/admin_AUT/.ssh/id_ed25519.pub

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