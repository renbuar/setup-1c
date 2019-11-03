#!/bin/sh -e
#/backup
#time sudo -u postgres pg_probackup-11 backup -B /backup --instance main -b FULL --stream --compress --delete-wal --expired -j4
#должна быть папка:
pgpass="'pass'"
PGVER=11
SERVER1C=u1804:1541
SERVERDB="'u1804 port=5432'"
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
sudo pg_dropcluster --stop $PGVER main
sudo pg_createcluster --locale ru_RU.UTF-8 $PGVER main --  --data-checksums
sudo /bin/su postgres -c "rm -rf /var/lib/postgresql/$PGVER/main/*"
sudo -u postgres pg_probackup-$PGVER restore -B /backup --instance main -D \
     /var/lib/postgresql/$PGVER/main  --log-level-file=info -j4
grep completed $log > /dev/null 2>&1
if [ $? -ne 0 ]
then
    msg="кластер main неудачное восстановление"
    FLAG=true
else
    msg="кластер main удачное восстановление"
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

#sudo -u postgres cp /etc/postgresql/$PGVER/main/postgresql.conf.bak /etc/postgresql/$PGVER/main/postgresql.conf
sudo cat >> /etc/postgresql/$PGVER/main/postgresql.conf <<EOF
# DB Version: 11
# OS Type: linux
# DB Type: oltp
# Total Memory (RAM): 16 GB
# Data Storage: ssd

max_connections = 1000
shared_buffers = 4GB
temp_buffers = 256MB
work_mem = 64MB
effective_cache_size = 8GB # 4GB for 1c
maintenance_work_mem = 1GB
wal_buffers = 16MB
min_wal_size = 2GB
max_wal_size = 4GB

default_statistics_target = 100
effective_io_concurrency = 2
random_page_cost = 1.1
autovacuum = on
autovacuum_max_workers = 4
autovacuum_naptime = 20s
bgwriter_delay = 20ms
bgwriter_lru_multiplier = 4.0
bgwriter_lru_maxpages = 400
synchronous_commit = off
checkpoint_completion_target = 0.9
ssl = off
fsync = on
commit_delay = 1000
commit_siblings = 5
row_security = off
max_files_per_process = 1000
standard_conforming_strings = off
escape_string_warning = off
max_locks_per_transaction = 256
#log_min_duration_statement = 0
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
#log_autovacuum_min_duration = 0
#log_duration = on
#log_statement = all
log_destination = stderr
plantuner.fix_empty_table = 'on'
online_analyze.table_type = 'temporary'
online_analyze.verbose = 'off'
max_wal_senders = 10
wal_level = replica
unix_socket_directories='/var/run/postgresql'
# Для настройки архивного резервного копирования разкомментировать:
archive_mode = on
#archive_command ='test ! -f /wal/%f && cp %p /wal/%f'
archive_command = '/usr/bin/pg_probackup-11 archive-push -B /backup --compress \
  --instance main --wal-file-path %p --wal-file-name %f'
EOF
sudo pg_ctlcluster $PGVER main start
sudo -u postgres psql -U postgres -c "alter user postgres with password $pgpass;"
sudo -u postgres psql -p 5432 -c "\l"
#fi

#if false; then

#sudo systemctl stop srv1cv83.service
sudo systemctl stop server1c-8.3.15.1700.service
#sudo rm -rf /home/usr1cv8/.1cv8
sudo rm -rf /home/usr1cv8/.server1c-8.3.15.1700
#sudo systemctl start srv1cv83.service
sudo systemctl start server1c-8.3.15.1700.service
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
     TEST=false
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
#fi
#============================================
