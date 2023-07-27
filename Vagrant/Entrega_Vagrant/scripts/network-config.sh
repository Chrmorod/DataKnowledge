#!/bin/bash
# network-config.sh
# Autores: Christian Molina Rodríguez / Pau Ros Bou
# Versión: Noviembre 2022

#
# NOTA PREVIA GENERAL:
# 
#       En este script se han omitido expresamente algunas comprobaciones
#       previas a cada acción, y en general todas las comprobaciones de error.
#       Se deja al alumno que las implemente como desee, así como algunas acciones
#       que se comentan pero no se resuelven.
#

# En primer lugar importamos el fichero common.sh que define constantes comunes a todos los
# scripts. Revisa este fichero para saber cuales son estas variables:
source /vagrant/scripts/common.sh
# PARAMETROS DE ENTRADA, en orden (se pasan desde Vagrantfile):
#
#  $1: nombre_host (string): nombre del sistema invitado (sin sufijo DNS).
#                          	Parámetro obligatorio.
nombre_host=$1
#  $2: IP_host (dirección IP): dirección IP del sistema en la red privada.
#                         	Parámetro obligatorio.
IP_host=$2
#  $3: IP_DNS (dirección IP): dirección IP del servidor DNS, si hay que cambiarlo.
#                          	Parámetro opcional.
IP_DNS=$3
# 0) Comprobación previa de parámetros de entrada obligatorios
# if...
if [ -z "$nombre_host" ]
then
    echo "Falta el nombre del servidor invitado"
    exit 1
fi
if [ -z "$IP_host" ]
then
    echo "Falta la ip del servidor invitado"
    exit 1
fi
#IP_DNS se comprueba mas abajo en este fichero.
# fi

# 1) Establecer nombre de host 
fqdn="${nombre_host}.${DOMINIO}"
sudo hostname $fqdn

# 2) Modificar el /etc/hosts para incluir (al principio) el nombre del host y 
#    la IP en la red privada (si no están ya)
echo "${IP_host}  ${fqdn}  ${nombre_host}" > /tmp/nuevo-hosts 
cat  /etc/hosts >> /tmp/nuevo-hosts
sudo cp /tmp/nuevo-hosts /etc/hosts

# 3) Si se ha especificado un servidor DNS en los parámetros de entrada (IP_DNS), 
#    entonces reconfigurar el cliente DNS:
# NOTA: Sólo falta la comprobación
# if...
if ! [ -z "$IP_DNS" ]
then
	sudo nmcli con mod "System eth0" ipv4.ignore-auto-dns yes
	sudo nmcli con mod "System eth0" ipv4.dns "${IP_DNS} 8.8.8.8"
	sudo nmcli con mod "System eth0" ipv4.dns-search ${DOMINIO}
fi
#fi

# 4) Restablecer la red para reflejar los cambios, y parar el cortafuegos
sudo systemctl restart network
sudo systemctl stop firewalld
sudo systemctl disable firewalld


