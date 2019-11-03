#!/bin/sh -e
#/backup
#time sudo -u postgres pg_probackup-11 backup -B /backup --instance main -b FULL --stream --compress --delete-wal --expired -j4
#должна быть папка:
pgpass="'pass'"
PGVER=11
SERVER1C=u1804:2541
SERVERDB="'u1804 port=5433'"
DBPASS=pass
ADMIN1C=admin
PWADMIN1C=admin
BACKUP_DIR=/backup
LOG0=$BACKUP_DIR/test.log
LOG1=$BACKUP_DIR/test1c.log
log=$BACKUP_DIR'/log/pg_probackup.log'

#должны быть права
#sudo chown -R postgres:postgres /backup
sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
#exit
#============================================
#if false; then
sudo pg_dropcluster --stop $PGVER beta
sudo pg_createcluster --locale ru_RU.UTF-8 $PGVER beta --  --data-checksums
sudo /bin/su postgres -c "rm -rf /var/lib/postgresql/$PGVER/beta/*"
sudo -u postgres pg_probackup-$PGVER restore -B /backup --instance main -D \
     /var/lib/postgresql/$PGVER/beta  --log-level-file=info -j4
grep completed $log > /dev/null 2>&1
if [ $? -ne 0 ]
then
    msg="кластер beta неудачное восстановление"
    FLAG=true
else
    msg="кластер beta удачное восстановление"
    FLAG=false
fi
DATA=`date +"%Y-%m-%d %H:%M:%S"`
echo $msg
sudo su postgres -c "echo '$DATA $msg' >> $LOG1"
sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
sudo su postgres -c "cat $log >> $LOG1"
sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"

if $FLAG; then
    sudo su postgres -c "echo 'Завершение работы'>> $LOG1"
    sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
    echo "Завершение работы"
    exit 1
fi

#sudo -u postgres cp /etc/postgresql/$PGVER/beta/postgresql.conf.bak /etc/postgresql/$PGVER/beta/postgresql.conf
sudo pg_ctlcluster $PGVER beta status
sudo pg_ctlcluster $PGVER beta start
sudo pg_ctlcluster $PGVER beta status
#sudo -u postgres psql -U postgres -c "alter user postgres with password $pgpass;"
sudo -u postgres psql -p 5433 -c "\l"
#fi

#if false; then

#sudo systemctl stop srv1cv83.service
sudo systemctl stop test1c-8.3.15.1700.service
#sudo rm -rf /home/usr1cv8/.1cv8
sudo rm -rf /home/usr1cv8/.test1c-8.3.15.1700
#sudo systemctl start srv1cv83.service
sudo systemctl start test1c-8.3.15.1700.service
# делаем  backup
DB_BASE=`sudo su postgres -c "/usr/bin/psql -qAt -c 'SELECT * FROM pg_database;'" | \
     cut -d"|" -f1 | /bin/grep -v template | /bin/grep -v postgres`
#DB_BASE="demo test" #конкретные базы
#DB_BASE="" #пропустить
#DB_BASE="" #пропустить
echo $DB_BASE
for DB_NAME in $DB_BASE
 do
     echo $DB_NAME
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     DATA1=`date +"%Y-%m-%d %H:%M:%S"`
     # Записываем информацию в лог с секундами
     sudo su postgres -c "echo '$DATA1 Начало создания базы ${DB_NAME}' >> $LOG1"
     #sudo su postgres -c "xvfb-run /opt/1C/v8.3/x86_64/./1cv8 CREATEINFOBASE Srvr=\"$SERVER1C;Ref=$DB_NAME;\
     #DBMS='PostgreSQL';DBSrvr=$SERVERDB;DB=$DB_NAME;DBUID='postgres';DBPwd=$DBPASS;\
     #CrSQLDB='Y';SchJobDn='N';\" /Out "$LOG0" > /dev/null 2>&1"
     sudo su postgres -c "xvfb-run /opt/1C/v8.3.15.1700/x86_64/./1cv8 CREATEINFOBASE Srvr=\"$SERVER1C;Ref=$DB_NAME;\
     DBMS='PostgreSQL';DBSrvr=$SERVERDB;DB=$DB_NAME;DBUID='postgres';DBPwd=$DBPASS;\
     CrSQLDB='Y';SchJobDn='N';\" /Out "$LOG0" > /dev/null 2>&1"
     if [ $? -ne 0 ]
     then
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Ошибка создания базы ${DB_NAME}"
         sudo su postgres -c "cat $LOG0 >> $LOG1"
         sudo su postgres -c "echo '$DATA1 Ошибка создания базы ${DB_NAME}' >>  $LOG1"
         TEST=false
     else
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Завершение создания базы ${DB_NAME}"
         sudo su postgres -c "cat $LOG0 >> $LOG1"
         sudo su postgres -c "echo '$DATA1 Завершение создания базы ${DB_NAME}' >>  $LOG1"
         TEST=true
     fi
     sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
     #Запретить тестирование и исправление TEST=false
     #TEST=false
     if $TEST; then
     # Записываем информацию в лог с секундами
     DATA1=`date +"%Y-%m-%d %H:%M:%S"`
     echo "$DATA1 Начало тестирования базы ${DB_NAME}"
     sudo su postgres -c "echo '$DATA1 Начало тестирования базы ${DB_NAME}' >>  $LOG1"
     #sudo su postgres -c "xvfb-run /opt/1C/v8.3/x86_64/./1cv8 DESIGNER /S$SERVER1C'\'$DB_NAME /N$ADMIN1C\
     #    /P$PWADMIN1C /IBcheckAndRepair -LogAndRefsIntegrity /Out $LOG0 > /dev/null 2>&1"
     sudo su postgres -c "xvfb-run /opt/1C/v8.3.15.1700/x86_64/./1cv8 DESIGNER /S$SERVER1C'\'$DB_NAME /N$ADMIN1C\
         /P$PWADMIN1C /IBcheckAndRepair -LogAndRefsIntegrity /Out $LOG0 > /dev/null 2>&1"

     if [ $? -ne 0 ]
     then
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Ошибка тестирования базы ${DB_NAME}"
         sudo su postgres -c "cat $LOG0 >> $LOG1"
         sudo su postgres -c "echo '$DATA1 Ошибка тестирования базы ${DB_NAME}' >>  $LOG1"
     else
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Завершение тестирования базы ${DB_NAME}"
         sudo su postgres -c "cat $LOG0 >> $LOG1"
         sudo su postgres -c "echo '$DATA1 Завершение тестирования базы ${DB_NAME}' >>  $LOG1"
     fi
     sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
     fi
done

#sudo systemctl stop srv1cv83.service
#sudo pg_ctlcluster $PGVER main stop
sudo systemctl stop test1c-8.3.15.1700.service
#sudo systemctl disable test1c-8.3.15.1700.service
sudo pg_ctlcluster $PGVER beta stop
#sudo pg_dropcluster --stop $PGVER beta
#fi
#============================================
