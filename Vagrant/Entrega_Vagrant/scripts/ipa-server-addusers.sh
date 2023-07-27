#!/bin/bash
# ipa-server-addusers.sh
# Autor: Andrés Terasa 
# Versión: septiembre 2022

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
#  $1: fich_usuarios (fichero): nombre de fichero CSV que contiene los 
#                               usuarios que hay que crear en el dominio.
#                              Parámetro obligatorio.
#
#       En el fichero CSV hay una línea por cada usuario, y sus datos son los
#       siguientes, en orden y separados por comas:
#
#       login_name,contraseña,Nombre,Apellidos
#
fich_usuarios=$1
declare -i cnt=1
declare -A login_name
while IFS=,
read -r -a line; do
    login_name["${line[0]}"]="$cnt"
    declare -n arr="array$cnt"
    unset line[0]
    declare -a arr=("${line[@]}")
    ((cnt++))
done < ${fich_usuarios}
# 0) Comprobación previa de parámetros de entrada obligatorios.


# 1) Comprobación de la existencia del fichero de usuarios (ubicado en el mismo directorio
# que el propio script) y en caso contrario salimos del script con error.


# 2) Comprobación de la existencia del dominio IPA (solicitando un tique kerberos para
#    el admin@ADMON.LAB), y en caso contrario salimos del script con error. 


# 3) Procesamiento del fichero CSV:
#
# Para cada línea:
#  Comprobamos si el usuario ya existe, mediante la orden
#     ipa user-show ${login_name} 
#  y en caso contradio lo creamos, mediante la orden
#     ipa user-add ${login_name} --first ${Nombre} --last $ {Apellidos} --password
#
#







