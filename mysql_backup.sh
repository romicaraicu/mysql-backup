#!/bin/bash

BACKUP_DIR="/path/to/backup/dir/"
DATE=`date +%Y%m%d`
DATETIME=`date +%Y%m%d%H%M`

MyUSER="user"
MyPASS="pass"
MyHOST="localhost"

if [ ! -d $BACKUP_DIR/$DATE ]; then
    mkdir -p $BACKUP_DIR/$DATE
fi

DBS="$(/usr/bin/mysql -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"

for i in $DBS
do
/usr/bin/mysqldump -u $MyUSER -h $MyHOST -p$MyPASS --routines --skip-lock-tables $i | /usr/bin/nice -n 19 /usr/bin/gzip >  $BACKUP_DIR/$DATE/$i"_"$DATETIME.sql.gz
done

mysqlcheck -h $MyHOST -u $MyUSER -p --analyze --silent --password=$MyPASS --all-databases 1>>$BACKUP_DIR/$DATE/mysqlcheck_$DATETIME.log
mysqlcheck -h $MyHOST -u $MyUSER -p --check --silent --password=$MyPASS --all-databases 1>>$BACKUP_DIR/$DATE/mysqlcheck_$DATETIME.log
mysqlcheck -h $MyHOST -u $MyUSER -p --optimize --silent --password=$MyPASS --all-databases 1>>$BACKUP_DIR/$DATE/mysqlcheck_$DATETIME.log
mysqlcheck -h $MyHOST -u $MyUSER -p --repair --silent --password=$MyPASS --all-databases 1>>$BACKUP_DIR/$DATE/mysqlcheck_$DATETIME.log
###### remove old backups part
if [ -d $BACKUP_DIR ]; then
    ## clear old DB backups
    find $BACKUP_DIR/* -maxdepth 0 -mtime +10 -print0 -type d | xargs --no-run-if-empty -0 rm -rf
## Force rights & access
    chown -R mysql:mysql $BACKUP_DIR
    find $BACKUP_DIR -type d -exec chmod 700 '{}' ';'
    find $BACKUP_DIR -type f -exec chmod 600 '{}' ';'
fi

