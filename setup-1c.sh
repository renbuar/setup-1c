#!/bin/bash
set -e
#sudo rm -rf dist
#mkdir dist
#echo "Please enter https://releases.1c.ru/ credentials"
#IFS=""
#read -p "Login: " USERNAME
#read -p "Password: " PASSWORD
read -p "Version: " VERSION

export FIRST=true #true первоначальная установка #false дополнительные установки
export CLIENT=true #true установка клиента #false клиент не ставим
#export USERNAME
#export PASSWORD
export VERSION
export PORT=1540
export REGPORT=1541
export RANGE=1560:1690
export RASPORT=1545
export USR1CV8=usr1cv8
export GROUP1CV8=grp1cv8 
export SERVICENAME=server1c

./build.sh
