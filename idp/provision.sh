#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando idp "
echo "########################################"

# --- 1. Leer .env directamente desde la carpeta compartida /vagrant ---
if [ -f /vagrant/.env ]; then
  eval $(sed -e 's/^\xEF\xBB\xBF//' -e 's/\r$//' /vagrant/.env | grep -v '^#')
fi

# Valores por defecto si no están definidos
DOMINIO="${DOMINIO:-aut.internal}"
ORGANIZACION="${ORGANIZACION:-Empresa AUT}"
LDAP_ADMIN_PASS="${LDAP_ADMIN_PASS:-Admin123456!}"

echo "Actualizando repositorios"
apt-get update -y
apt-get install -y net-tools iputils-ping curl tcpdump nmap

BASE="dc=${DOMINIO//./,dc=}"
ADMIN="cn=admin,${BASE}"
LDIF=/vagrant/idp/ldap

# --- 2. Preconfigurar debconf e instalar OpenLDAP ---
debconf-set-selections <<EOL
slapd slapd/no_configuration boolean false
slapd slapd/domain string ${DOMINIO}
slapd shared/organization string ${ORGANIZACION}
slapd slapd/password1 password ${LDAP_ADMIN_PASS}
slapd slapd/password2 password ${LDAP_ADMIN_PASS}
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
EOL

apt-get install -y slapd ldap-utils easy-rsa
dpkg-reconfigure -f noninteractive slapd

# --- 3. Forzar la contraseña del superusuario admin en cn=config ---
PASS_HASH=$(slappasswd -s "$LDAP_ADMIN_PASS")
cat <<EOF | ldapmodify -Q -Y EXTERNAL -H ldapi:///
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $PASS_HASH
EOF

# --- 4. CA de la empresa: se restaura la copia de seguridad ---
if [ -f /vagrant/idp/ca/ca-backup.tgz ] && [ ! -d /root/ca ]; then
  tar xzf /vagrant/idp/ca/ca-backup.tgz -C /root
fi

# --- 5. StartTLS con certificado firmado por la CA y exigir cifrado ---
mkdir -p /etc/ldap/tls
cp /vagrant/idp/tls/ca.crt /vagrant/idp/tls/idp.crt /vagrant/idp/tls/idp.key /etc/ldap/tls/
chmod 644 /etc/ldap/tls/*.crt
chown root:openldap /etc/ldap/tls/idp.key
chmod 640 /etc/ldap/tls/idp.key

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f $LDIF/tls.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f $LDIF/exigir-tls.ldif

# --- 6. Módulo ppolicy y esquema openssh-lpk ---
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f $LDIF/ppolicy-modulo.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f $LDIF/openssh-lpk.ldif

# --- 7. Datos: estructura, grupos, usuarios, política y claves SSH (en orden) ---
for f in $LDIF/0*.ldif; do
  [ -f "$f" ] || continue
  echo "[*] Cargando $(basename $f)"
  ldapmodify -a -x -H ldapi:/// -D "$ADMIN" -w "$LDAP_ADMIN_PASS" -f "$f" || true
done

echo "------ FIN ------"