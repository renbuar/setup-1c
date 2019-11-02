#!/bin/bash
set -e
VERSION=11.5-1.1C

if [ -z "$VERSION" ]
then
    echo "VERSION not set"
    exit 1
fi

if ! [ -f dist/postgresql_${VERSION//-/_}_amd64_deb.tar.bz2 ]; then
    echo "Нет файла для установки - выходим"
    exit 1
fi

if ! [ -f dist/postgresql_${VERSION//-/_}_amd64_addon_deb.tar.bz2 ]; then
    echo "Нет файла для установки - выходим"
    exit 1
fi

wget http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu55_55.1-7_amd64.deb 
sudo dpkg -i libicu55_55.1-7_amd64.deb
dpkg -l | grep libicu55 | awk -F' ' '{print $2}' | sudo xargs apt-mark hold
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" \
 >> /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt-get install postgresql-common  -y 
dpkg -l | grep postgres | awk -F' ' '{print $2}' | sudo xargs apt-mark hold
sudo rm -rf  /tmp/post
mkdir -p /tmp/post
cp dist/postgresql_11.5_1.1C_amd64_deb.tar.bz2 /tmp/post/
cd /tmp/post
tar -xvf postgresql_11.5_1.1C_amd64_deb.tar.bz2
cd postgresql-11.5-1.1C_amd64_deb
sudo dpkg -i *.deb
dpkg -l | grep 11.5-1.1C | awk -F' ' '{print $2}' | sudo xargs apt-mark hold
sudo pg_dropcluster --stop 11 main
sudo pg_createcluster --locale ru_RU.UTF-8 11 main --  --data-checksums
sudo pg_ctlcluster 11 main start
sudo -u postgres psql -U postgres -c "alter user postgres with password 'pass';"
sudo cp /etc/postgresql/11/main/postgresql.conf /etc/postgresql/11/main/postgresql.conf.bak
sudo cat >> /etc/postgresql/11/main/postgresql.conf <<EOF
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
sudo su -c "echo 'deb [arch=amd64] http://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs)\
    main-$(lsb_release -cs)' > /etc/apt/sources.list.d/pg_probackup.list"
sudo su -c "wget -O - http://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG_PROBACKUP | apt-key add -" 
sudo apt-get update
sudo apt-get install pg-probackup-11
dpkg -l | grep pg-probackup-11 | awk -F' ' '{print $2}' | sudo xargs apt-mark hold
sudo pg_probackup-11 init -B /backup
sudo mkdir /backup/copy
sudo mkdir /backup/log
sudo mkdir /backup/pg_dump 
sudo chown -R postgres:postgres /backup/ 
sudo -u postgres pg_probackup-11 add-instance -B /backup -D /var/lib/postgresql/11/main --instance main
sudo pg_ctlcluster 11 main restart

sudo -u postgres -c "echo 'retention-redundancy=5' >> /backup/backups/main/pg_probackup.conf"
sudo pg_ctlcluster 11 main status
ss -tunpl | grep 5432
ps aux | grep postgres | grep -- -D
sudo -u postgres pg_probackup-11 backup -B /backup --instance main -b FULL --stream --compress --delete-wal --expired -j 4
sudo -u postgres pg_probackup-11 show -B /backup
