#!/bin/bash
# ipa-client-install.sh
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
#  (ninguno)
nombre_client=$1
fqdn="${nombre_client}.${DOMINIO}"
# 1) Comprobación de si los paquetes necesarios para el cliente IPA están instalados, 
# y en caso contrario instalación de los mismos:
packages="ipa-client"
# if...
if [ -z $(which $packages) ]
then
    sudo yum -y install $packages
fi
#fi
# 2) Comprobación de si el sistema ya es miembro del dominio IPA (comprobando si existe
#   el fichero /etc/ipa/default.conf), y en caso contrario lo añadimos al dominio: 

#if... Existe el fichero /etc/ipa/default.conf 
#then
if [ -f /etc/ipa/default.conf ]
then
   # Forzar el reinicio de la red e instalar el cliente IPA  
   sudo systemctl restart network
   # INSTALACION DESATENDIDA del cliente IPA
   sudo ipa-client-install --principal 'admin@ADMON.LAB' --password=${PASSWD_ADMIN} --hostname=${fqdn} --realm=${DOMINIO_KERBEROS} --enable-dns-updates --mkhomedir --unattended --force-join
fi
#fi


