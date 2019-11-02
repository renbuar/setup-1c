# setup-1c
Скрипт установки конкретной  версии сервера 1с от renbuar
Скрипт ./download.sh
взят:
https://github.com/Infactum/onec_dock 

За что большое спасибо!

## Использование

- Клонируем этот репозитарий

$ git clone https://github.com/renbuar/setup-1c.git

$ cd setup-1c

$ sh download.sh

Please enter https://releases.1c.ru/ credentials

Login: vasya

Password: pupkin

Version: 8.3.15.1565


Будут загружены в setup-1c/dist :

client_8_3_15_1565.deb64.tar.gz

deb64_8_3_15_1565.tar.gz



$ sudo sh setup-1c.sh

выполнена первоначальная установка сервера 1С на стандартные порты

server1c-8.3.15.1565-ras.service          enabled

server1c-8.3.15.1565.service              enabled

sudo systemctl status server1c-8.3.15.1565.service

sudo systemctl status server1c-8.3.15.1565-ras.service



Для установки дополнительных серверов

на нестанартные порты с шагом +200 (или +1000)

$ nano setup-1c.sh

Если нужно установить несколько серверов для одной платформы

задать уникальное имя

export SERVICENAME=obraz


```
export FIRST=false #true первоначальная установка #false дополнительные установки
export CLIENT=true #true установка клиента #false клиент не устанавливается
export VERSION=8.3.15.1656
export PORT=1740
export REGPORT=1741
export RANGE=1760:1890
export RASPORT=1745
export USR1CV8=usr1cv8
export GROUP1CV8=grp1cv8
#export SERVICENAME=server1c
export SERVICENAME=obraz


