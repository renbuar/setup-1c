#!/bin/sh -e
#/backup
#должна быть папка:
BACKUP_DIR=/backup/pg_dump
LOG1=$BACKUP_DIR/backup.log
#должны быть права
#sudo chown -R postgres:postgres /backup
sudo su postgres -c "echo '---------------------------------' >> $LOG1"
#exit
#============================================
# делаем  backup
DB_BASE=`sudo su postgres -c "/usr/bin/psql -qAt -c 'SELECT * FROM pg_database;'" | \
     cut -d"|" -f1 | /bin/grep -v template | /bin/grep -v postgres`
#DB_BASE="demo test" #конкретные базы
#DB_BASE="" #пропустить
echo $DB_BASE
for DB_NAME in $DB_BASE
 do
     DATA=`date +"%Y-%m-%d_%H-%M-%S"`
     DATA1=`date +"%Y-%m-%d %H:%M:%S"`
     # Записываем информацию в лог с секундами
     sudo su postgres -c "echo '$DATA1 Начало backup базы ${DB_NAME}' >> $LOG1"
     echo "$DATA1 Начало backup базы ${DB_NAME}"
     DIR=$BACKUP_DIR/$DB_NAME-$DATA
     sudo su postgres -c "mkdir -p $DIR"
     sudo su postgres -c "pg_dump -j 4 -F d -f $DIR $DB_NAME" && sudo su postgres -c \
     "cd $BACKUP_DIR; tar -cvzf $DB_NAME-$DATA.tar.gz $DB_NAME-$DATA > /dev/null 2>&1"
     if [ $? -ne 0 ]
     then
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Ошибка завершения backup для базы ${DB_NAME}"
         sudo su postgres -c "echo '$DATA1 Ошибка backup для для базы ${DB_NAME}' >>  $LOG1"
         sudo su postgres -c "rm -rf $DIR"
         sudo su postgres -c "rm -rf $DIR.tar.gz"
     else
         DATA1=`date +"%Y-%m-%d %H:%M:%S"`
         echo "$DATA1 Завершение backup для базы ${DB_NAME}"
         sudo su postgres -c "echo '$DATA1 Завершение backup для для базы ${DB_NAME}' >>  $LOG1"
         #sudo su postgres -c "rm -rf $DIR"
         #sudo su postgres -c "rm -rf $DIR.tar.gz"
     fi
     sudo su postgres -c "echo '--------------------------------------------------------------------' >> $LOG1"
done
#============================================
