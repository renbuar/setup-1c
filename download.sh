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

 ./load.sh

