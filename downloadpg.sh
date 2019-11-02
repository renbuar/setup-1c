#!/bin/bash
set -e
#sudo rm -rf dist
#mkdir dist
echo "Please enter https://releases.1c.ru/ credentials"
#IFS=""
read -p "Login: " USERNAME
read -p "Password: " PASSWORD
read -p "Version: " VERSION

#export USERNAME=vasij
export USERNAME
export PASSWORD
export VERSION
#export VERSION=11.5-1.1C
#export VERSION=10.10-1.1C
#export VERSION=10.9-5.1C
./loadpg.sh

