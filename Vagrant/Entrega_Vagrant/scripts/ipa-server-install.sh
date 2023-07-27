#!/bin/bash
# ipa-server-install.sh
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
#


# 0) Comprobación previa de parámetros de entrada obligatorios
# if...
nombre_host=$1
if [ -z "$nombre_host" ]
then
    echo "Falta el nombre del servidor invitado"
fi
# fi

fqdn="${nombre_host}.${DOMINIO}"

# 1) Comprobación de si los paquetes necesarios para el servidor IPA están instalados, 
# y en caso contrario instalación de los mismos:
packages="ipa-server ipa-server-dns ipa-bind bind-dyndb-ldap"
#if ...
	# NOTA: En las últimas versiones de CentOS ocurre un fallo al instalar el servidor IPA
	# cuya resolución requiere la actualización previa de ciertos paquetes (bibliotecas NSS).  
	# Para actualizar estos paquetes hay que ejecutar lo siguiente:
sudo yum update nss* -y
for j in $packages
do 
    if [ -z $(which $j) ]
    then
        sudo yum -y install $j
    fi
done
sudo yum update ipa* -y
#fi
# 2) Comprobación de la existencia del dominio IPA (solicitando un tique kerberos para
#    el administrador), y en caso contrario instalación del dominio: 
echo ${PASSWD_ADMIN} | kinit "admin@${DOMINIO_KERBEROS}" 2>/dev/null 1>/dev/null
if [[ "$?" != "0" ]]
then
   	# INSTALAR el servidor IPA (instalación desatendida) -- añadiendo external-ca me funciona pero no consigo verlo desde mi navegador.
    sudo ipa-server-install -a ${PASSWD_ADMIN} -p ${PASSWD_ADMIN} --hostname=${fqdn} -r ${DOMINIO_KERBEROS} -n ${DOMINIO} --setup-dns --no-forwarders -U #--external-ca -U
fi
