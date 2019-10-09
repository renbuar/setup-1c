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
$ sh setup-1c.sh
Please enter https://releases.1c.ru/ credentials
Login: vasya
Password: pupkin
Version: 8.3.15.1565

Будет выполнена первоначальная установка сервера 1С на стандартные порты

obraz-8.3.15.1565-ras.service          enabled
obraz-8.3.15.1565.service              enabled
sudo systemctl status obraz-8.3.15.1565.service
sudo systemctl status obraz-8.3.15.1565-ras.service


Для установки дополнительных серверов
на нестанартные порты с шагом +200 (или +1000)
$ nano setup-1c.sh
можно заполнить переменные окружения USERNAME, PASSWORD и VERSION,
содержащие логин/пароль к [сайту с дистрибутивами](http://releases.1c.ru) 
и версию платформы соответственно.
Если нужно установить несколько серверов для одной платформы
задать уникальное имя
export SERVICENAME=obraz

```
export FIRST=0 #1 первоначальная установка #0 дополнительные установки
export USERNAME=vasya
export PASSWORD=pupkin
export VERSION=8.3.15.1656
export PORT=1740
export REGPORT=1741
export RANGE=1760:1890
export RASPORT=1745
export USR1CV8=usr1cv8
export GROUP1CV8=grp1cv8
#export SERVICENAME=usr1cv8-
#export SERVICENAME=v
export SERVICENAME=obraz


