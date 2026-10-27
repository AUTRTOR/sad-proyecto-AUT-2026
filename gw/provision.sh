#!/usr/bin/env bash

# El script se detiene si hay errores
set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando Gateway "
echo "########################################"
echo "-----------------"
echo "Actualizando repositorios"
apt-get update -y && apt-get autoremove -y
apt-get install -y net-tools iputils-ping curl tcpdump nmap

# RESPUESTAS PREVIAS (DEBCONF) PARA IPTABLES-PERSISTENT (En una sola línea cada una)
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
apt-get install -y iptables-persistent

# Activamos enrutamiento de forma persistente
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-enrutamiento.conf
sysctl -p /etc/sysctl.d/99-enrutamiento.conf

# Hacemos NAT del tráfico saliente.
# Primero, limpiamos todas las reglas
iptables -F
iptables -t nat -F

echo "cortafuegos basico: hacemos nat"
sysctl -w net.ipv4.ip_forward=1

# Ajusta el '9' de las subredes por tu número de clase real (N)
iptables -t nat -A POSTROUTING -s 172.1.9.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.2.9.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.3.9.0/24 -o eth0 -j MASQUERADE

echo "Gateway configurado"

netfilter-persistent save