#!/bin/sh -e
# Внимание задать пароль PGPASSWORD !!!
#/backup
inst='/backup'
cd $inst
#sudo sh /root/terminate.sh
# vacuumdb
#sudo systemctl stop srv1cv8-ras.service
sudo systemctl stop server1c-8.3.15.1700-ras.service
#sudo systemctl stop srv1cv83.service
sudo systemctl stop server1c-8.3.15.1700.service

DATA=`date +"%Y-%m-%d_%H-%M-%S"`
sudo su postgres -c "echo 'vacuumdb $DATA - начало' > $inst/vacuumdb.txt"
#sudo su postgres -c "vacuumdb -afz >> $inst/vacuumdb.txt"
if [ $? -ne 0 ]
then
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     sudo su postgres -c "echo 'vacuumdb $DATA - неудачное завершение' >> $inst/vacuumdb.txt"
else
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     sudo su postgres -c "echo 'vacuumdb $DATA - удачное завершение' >> $inst/vacuumdb.txt"
fi
sudo su postgres -c "echo '-------------------------------------------' >> $inst/vacuumdb.txt"
sudo su postgres -c "cat vacuumdb.txt >> vacuumdb.log"
cat vacuumdb.txt | mutt -s "vacuumdb" root
#  /backup/pg_probackup
log=$inst'/log/pg_probackup.log'
log1=$inst'/log/probackup.log'
if [ -f $log ]; then rm $log; fi
cd $inst
sudo su postgres -c "PGPASSWORD=pass pg_probackup-11 backup -B $inst --instance main \
    -U postgres -d postgres -h 127.0.0.1 -b FULL --stream --compress --expired --delete-wal \
    --log-level-file=info -j 4"
grep completed $log > /dev/null 2>&1
if [ $? -ne 0 ]
then
    msg="$inst неудачное завершение."
else
    msg="$inst удачное завершение."
fi
DATA=`date +"%Y-%m-%d %H:%M:%S"`
msg1="Размер экземпляра pg_probackup: $(du -h -s $inst/backups)"
sudo su postgres -c "echo '$DATA $msg' >> $log"
sudo su postgres -c "echo '$DATA $msg1' >> $log"
sudo su postgres -c "echo '==================================================================' >> $log"
sudo su postgres -c "cat $log >> $log1"
cat $log  | mutt -s "pg_probackup" root
#echo "$DATA $msg" >> $log1
# Сразу архивируем для rsync
#COPY_DIR=$inst/copy
#COPY_DIR=/backups/copy
COPY_DIR=/backup/copy
#COPY_LOG=$inst/copy/copy.log
#COPY_LOG=/backups/copy/copy.log
COPY_LOG=/backup/copy/copy.log
#Берем последнюю копию
COPY_ID=$(ls $inst/backups/main -1 | tail -1)
#Она должна быть completed
grep "$COPY_ID completed" $log > /dev/null 2>&1
if [ $? = 0 ]
then
    DATA=`date +"%Y-%m-%d_%H-%M-%S"`
    #rm  $inst/copy/*
    sudo su postgres -c "tar -cvzf $COPY_DIR/pg_pro-$DATA.tar.gz  \
           $inst/backups/main/$COPY_ID > /dev/null 2>&1"
    if [ $? = 0 ]
    then
        msg="создан $COPY_DIR/pg_pro-$DATA.tar.gz"
    else
        msg="ошибка создания $COPY_DIR/pg_pro-$DATA.tar.gz"
    fi
    DATA=`date +"%Y-%m-%d %H:%M:%S"`
    sudo su postgres -c "echo '$DATA $msg' >> $COPY_LOG"
    echo "$DATA $msg" | mutt -s "copy pg_probackup" root
fi
BACKUP_DIR="/backup/pg_dump"
#BACKUP_DIR="/backups/pg_dump"
cd $BACKUP_DIR
echo "====================================================================" > $BACKUP_DIR/backup.log
# Устанавливаем дату
DATA=`date +"%Y-%m-%d_%H-%M-%S"`
DATA_NAME=`date +"%Y-%m-%d_%H-%M-%S"`
echo "$DATA Size database file: " >> $BACKUP_DIR/backup.log
sudo du -h -s /var/lib/postgresql/11/main/base  >> $BACKUP_DIR/backup.log
echo "--------------------------------------------------------------------" >> $BACKUP_DIR/backup.log
# делаем  backup
DB_BASE=`sudo /bin/su postgres -c "/usr/bin/psql -qAt -c 'SELECT * FROM pg_database;'" | \
     cut -d"|" -f1 | /bin/grep -v template | /bin/grep -v postgres`
#DB_BASE="demo test" #конкретные базы
#DB_BASE="" #пропустить
echo $DB_BASE
for DB_NAME in $DB_BASE
 do
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     # Записываем информацию в лог с секундами
     echo "$DATA Начало backup базы ${DB_NAME}" >> $BACKUP_DIR/backup.log
     # Бэкапим базу данных demo и сразу сжимаем
     echo "$DATA Начало backup базы ${DB_NAME}"
     sudo /bin/su postgres -c "pg_dump -Fc ${DB_NAME}"  > $BACKUP_DIR/${DB_NAME}_$DATA_NAME.dump
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     if [ $? -ne 0 ]
     then
         echo "$DATA Ошибка завершения backup для базы ${DB_NAME}"
         echo "$DATA Ошибка завершения backup для для базы ${DB_NAME}" >> $BACKUP_DIR/backup.log
         exit
     else
          echo "$DATA Успешное завершение backup для базы ${DB_NAME}"
          echo "$DATA Успешное завершение backup для базы ${DB_NAME}" >> $BACKUP_DIR/backup.log
     fi
     echo "--------------------------------------------------------------------" >> $BACKUP_DIR/backup.log
done
# запускаем сервер 1С
echo "Запускаем сервер 1С"
#sudo systemctl start srv1cv83.service
sudo systemctl start server1c-8.3.15.1700.service
#sudo systemctl start srv1cv8-ras.service
sudo systemctl start server1c-8.3.15.1700-ras.service

#echo "Состояние сервера 1С"  >> $BACKUP_DIR/backup.log
#sudo systemctl status  srv1cv83.service | grep 'Active:' >> $BACKUP_DIR/backup.log
#sudo systemctl status  server1c-8.3.15.1700.service | grep 'Active:' >> $BACKUP_DIR/backup.log
echo "--------------------------------------------------------------------" >> $BACKUP_DIR/backup.log
echo "Закончено"
cat $BACKUP_DIR/backup.log >> $BACKUP_DIR/backupall.log
cat $BACKUP_DIR/backup.log | mutt -s "backup" root
