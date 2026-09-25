# Proyecto SAD

Este proyecto es para el módulo de Seguridad y Alta Disponibilidad (SAD) de 2º de ASIR. Básicamente, consiste en montar una pequeña red de empresa usando máquinas virtuales con VirtualBox y Vagrant, y probar diferentes medidas de seguridad.

## 1. Estructura de la red

La red está dividida en varias partes para tener los equipos y servidores separados.

### Gateway y router (gw)

Es el equipo principal de la red. Utiliza Ubuntu 24.04 y se encarga de conectar las diferentes redes entre sí, además de controlar el tráfico y hacer de firewall y VPN

### Red de Gestión e Intranet

Es la red donde están los servidores internos de la empresa.

- **idp:** servidor Ubuntu con OpenLDAP para gestionar usuarios.
- **backup-srv:** servidor Alpine encargado de realizar copias de seguridad de los demás servidores mediante `rsync` y `cron`.

### Red de Empleados

Es la red donde están los ordenadores de los trabajadores.

- **adminpc:** equipo utilizado por el administrador para gestionar el resto de máquinas mediante SSH y scripts.
- **empleado:** equipo que simula el ordenador de un trabajador normal.

La navegación de los empleados está controlada mediante el proxy.

### DMZ

En la DMZ están los servicios que tienen que estar más accesibles desde el exterior.

- **proxy:** servidor Ubuntu con Squid que controla y filtra la navegación de los empleados.
- **www:** servidor Alpine que aloja la página web de la empresa y DVWA, utilizado para realizar prácticas de Pentesting.

## 2. Despliegue del proyecto

Para poder utilizar el proyecto necesitamos tener instalados:

- Git
- VirtualBox
- Vagrant

Primero clonamos el repositorio:

```bash
git clone https://github.com/AUTRTOR/sad-proyecto-AUT-2026.git
```

Entramos en la carpeta y levantamos todas las máquinas virtuales:

```bash
cd SAD
vagrant up
```

Cuando termine, podemos comprobar que las máquinas están funcionando correctamente con:

```bash
vagrant status
```

Por último, podemos acceder a cualquier máquina mediante SSH usando Vagrant. Por ejemplo, para entrar en el servidor web:

```bash
vagrant ssh www
```