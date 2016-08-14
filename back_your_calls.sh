#!/bin/bash

#USAGE: ./0$ <clients_login>
#`record_fname` field contains full path to call record

UNAME=$1
SRC_DIR="/home/cb_asterisk/trash/"
DST_DIR="/home/cb_asterisk/include/clients/$UNAME/call_records"

CNT_FILES=$(mysql -u$MYSQL_USER -p$MYSQL_PASS cb_asterisk -BN -e"select count(record_fname) from logger where uname='$UNAME' and duration>0")
CP_FILES=0

for file in $( mysql -u$MYSQL_USER -p$MYSQL_PASS cb_asterisk -BN -e"select record_fname from logger where uname='$UNAME' and duration>0" ); do
	if cp $SRC_DIR${file##*/} $DST_DIR; then
		printf "($((CP_FILES++))/$CNT_FILES) copied           \r"
	fi	
done
echo "I've copied $CP_FILES files from $CNT_FILES metioned in database"
