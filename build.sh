#!/bin/bash
set -e


if [ -z "$VERSION" ]
then
    echo "VERSION not set"
    exit 1
fi

if ! [ -f dist/server.tar.gz ]; then
    echo "Нет файла для установки - выходим"
    exit 1
fi

#sudo rm -rf  /opt/1C/v$VERSION/
sudo rm -rf  /tmp/1ctmp
mkdir -p /tmp/1ctmp

# Если группы нет создаем
if [ $(getent group $GROUP1CV8) ]; then
    echo "группа $GROUP1CV8 существует - пропускаем"
else
    echo "группа $GROUP1CV8 не существует - создаем"
    sudo groupadd $GROUP1CV8
fi

# Если пользователя нет создаем
if ! id -u $USR1CV8 > /dev/null 2>&1; then
    echo "Пользователь $USR1CV8 не существует - создаем"
    sudo useradd -g $GROUP1CV8 -m -d /home/$USR1CV8 $USR1CV8
else
    echo "Пользователь $USR1CV8 существует - пропускаем"
fi


# Если папка с версией есть пропускаем
# Предполагаем что одна версия 1С от одного пользователя
if ! [ -d /opt/1C/v$VERSION/ ]; then
    echo "папка /opt/1C/v$VERSION/ не существует - создаем"
    cp dist/server.tar.gz /tmp/1ctmp
    cd /tmp/1ctmp
    tar xvzf /tmp/1ctmp/server.tar.gz
    mkdir /tmp/1ctmp/tmp
    dpkg-deb -x /tmp/1ctmp/1c-enterprise83-common_*_amd64.deb /tmp/1ctmp/tmp
    dpkg-deb -x 1c-enterprise83-server_*_amd64.deb /tmp/1ctmp/tmp
    sudo mkdir -p /opt/1C/
    sudo mv tmp/opt/1C/v8.3/ /opt/1C/v$VERSION/
    sudo chown -R $USR1CV8:$GROUP1CV8 /opt/1C
else
    echo "папка /opt/1C/v$VERSION/ существует - пропускаем"
fi

#sudo userdel usr1cv8
#sudo groupdel grp1cv8

#  Если первоначальная установка
if [ "$FIRST" -eq 1 ]
then
    echo первоначальная установка
    sudo apt install imagemagick -y
    sudo apt install libfreetype6 libgsf-1-common unixodbc glib2.0 -y
    sudo  apt install xfonts-utils cabextract -y
    sudo apt install ttf-mscorefonts-installer -y
    #$ sudo dpkg -i fonts-ttf-ms_1.0-eter4ubuntu_all.deb
    sudo fc-cache -fv
    sudo  apt install -y libc6-i386
    cd /tmp/1ctmp
    wget http://download.etersoft.ru/pub/Etersoft/HASP/last/x86_64/Ubuntu/18.04/haspd-modules_7.90-eter2ubuntu_amd64.deb
    wget http://download.etersoft.ru/pub/Etersoft/HASP/last/x86_64/Ubuntu/18.04/haspd_7.90-eter2ubuntu_amd64.deb
    sudo dpkg -i haspd_7.90-eter2ubuntu_amd64.deb
    sudo dpkg -i haspd-modules_7.90-eter2ubuntu_amd64.deb
    #$ sudo apt-get install -f -y
    sudo service haspd start
    #sudo service haspd status 
fi  

DATADIR=/home/$USR1CV8/.$SERVICENAME-$VERSION/1C/1Cv83
sudo cat > /tmp/1ctmp/$SERVICENAME-$VERSION.service <<EOF
# $SERVICENAME-$VERSION.service
#
[Unit]
Description=1C:Enterprise Server
Wants=network.target
After=network.target

[Service]
#MemoryAccounting=true
#MemoryLimit=15G
Type=simple
Environment=LANG=ru_RU.UTF-8
Environment=TZ=Europe/Moscow
Environment=PORT=$PORT
Environment=REGPORT=$REGPORT
Environment=RANGE=$RANGE
Environment=DATADIR=$DATADIR
PrivateTmp=yes
ExecStart=/opt/1C/v$VERSION/x86_64/ragent -d $DATADIR -port $PORT -regport $REGPORT -range $RANGE

# -seclev 0 -debug
Restart=always
RestartSec=3
User=$USR1CV8
Group=$GROUP1CV8

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/1ctmp/$SERVICENAME-$VERSION.service /etc/systemd/system/
sudo systemctl start $SERVICENAME-$VERSION.service
sudo systemctl enable $SERVICENAME-$VERSION.service



sudo cat > /tmp/1ctmp/$SERVICENAME-$VERSION-ras.service <<EOF
#
#$SERVICENAME-$VERSION-ras.service

[Unit]
Description=1C:Enterprise Remote Administration Service
After=network.target remote-fs.target nss-lookup.target
Requires=$SERVICENAME-$VERSION.service

[Service]
Type=simple
Environment=PORT=$PORT
Environment=RASPORT=$RASPORT
PrivateTmp=yes
ExecStart=/opt/1C/v$VERSION/x86_64/ras cluster localhost:$PORT --port=$RASPORT
KillSignal=SIGINT
PrivateTmp=true
Restart=on-failure
RestartSec=5
User=$USR1CV8
Group=$GROUP1CV8

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/1ctmp/$SERVICENAME-$VERSION-ras.service /etc/systemd/system/
sudo systemctl start $SERVICENAME-$VERSION-ras.service
sudo systemctl enable $SERVICENAME-$VERSION-ras.service

systemctl list-unit-files | grep 8.3.
echo "sudo systemctl status $SERVICENAME-$VERSION.service"
echo "sudo systemctl status $SERVICENAME-$VERSION-ras.service"
