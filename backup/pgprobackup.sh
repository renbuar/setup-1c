#!/bin/sh -e
# Внимание задать пароль PGPASSWORD !!!
#/backup
inst='/backup'
cd $inst
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
#cat $log  | mutt -s "pg_probackup" root
#echo "$DATA $msg" >> $log1
# Сразу архивируем для rsync
#COPY_DIR=$inst/copy
COPY_DIR=/backup/copy
#COPY_LOG=$inst/copy/copy.log
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
    #echo "$DATA $msg" | mutt -s "copy pg_probackup" root
fi
