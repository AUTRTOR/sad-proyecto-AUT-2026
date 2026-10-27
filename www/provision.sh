#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "########################################"
echo "Aprovisionando WWW"
echo "########################################"
apt-get update -y
apt-get install -y nginx openssl php-fpm php-opcache php-gd php-mysql php-curl
PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

mkdir -p /etc/ssl/private /etc/ssl/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=ES/ST=Almeria/L=Almeria/O=IES_CELIA_VINAS/OU=IT/CN=localhost"

rm -f /etc/nginx/sites-enabled/default
cat <<'NGINX' > /etc/nginx/sites-available/servidor_web
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name localhost;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    root /var/www/html;
    index index.php index.html;
    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/servidor_web /etc/nginx/sites-enabled/servidor_web

sed -i 's/^pm.max_children = .*/pm.max_children = 3/' /etc/php/$PHPV/fpm/pool.d/www.conf

rm -f /var/www/html/index.nginx-debian.html
cat > /var/www/html/index.php << 'HTML'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Servidor WWW - DMZ</title></head>
<body>
    <h1>¡Hola! Estás en el servidor WWW</h1>
    <p>Dirección IP del servidor: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
    <p><a href="info.php">Ver PHP Info</a></p>
</body>
</html>
HTML
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown -R www-data:www-data /var/www/html

nginx -t
systemctl enable php$PHPV-fpm nginx
systemctl restart php$PHPV-fpm nginx

echo "=> Blindando acceso SSH en www... "
id admin_AUT >/dev/null 2>&1 || useradd -m -s /bin/bash admin_AUT
usermod -aG sudo admin_AUT
mkdir -p /home/admin_AUT/.ssh
sed 's/\r$//' /tmp/id_ed25519.pub > /home/admin_AUT/.ssh/authorized_keys
chown -R admin_AUT:admin_AUT /home/admin_AUT/.ssh
chmod 700 /home/admin_AUT/.ssh
chmod 600 /home/admin_AUT/.ssh/authorized_keys

cat > /etc/ssh/sshd_config.d/00-bastionado.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
EOF
sshd -t
systemctl restart ssh

grep -q '^interface eth0' /etc/dhcpcd.conf || cat >> /etc/dhcpcd.conf <<'EOF'
interface eth0
nogateway
EOF
echo "------ FIN ------"