#!/bin/bash
set -e
#sudo rm -rf dist
#mkdir dist
#echo "Please enter https://releases.1c.ru/ credentials"
#IFS=""
#read -p "Login: " USERNAME
#read -p "Password: " PASSWORD
read -p "Version: " VERSION

export FIRST=false #true первоначальная установка #false дополнительные установки
export CLIENT=true #true установка клиента #false клиент не ставим
#export USERNAME
#export PASSWORD
export VERSION
export PORT=2540
export REGPORT=2541
export RANGE=2560:2690
export RASPORT=2545
export USR1CV8=usr1cv8
export GROUP1CV8=grp1cv8 
export SERVICENAME=test1c

./build.sh
