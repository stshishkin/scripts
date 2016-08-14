#!/bin/bash

# script for moving call-files from temporary directoty to astspooldir with a little overflow protection
# USAGE: $0 <temp_dir> <astspooldir> <number_files>
# example: $0 /tmp/calldir /var/spool/asterisk/outgoing 100

SRC_DIR=$1
DST_DIR=$2
MAX_FILES=$3
CNT_MOVED=0

report () {
	echo "I've moved" $CNT_MOVED "files"
}

trap report 1

while true; do
	CNT_FILES=$(ls -1 $DST_DIR | wc -l)
	OLD_FILE=$SRC_DIR/$(ls -1t $SRC_DIR | tail -1 )
	if [ $CNT_FILES -lt $MAX_FILES ]; then  
		if [ -f $OLD_FILE ]; then
			mv $OLD_FILE $DST_DIR
			((CNT_MOVED++))
		fi
	else
		NEW_FILE=$DST_DIR/$(ls -1t $DST_DIR | head -1 )
		if [ "$(stat -c%Y $NEW_FILE)" -lt "$(stat -c%Y $OLD_FILE)" ]; then
			mv $OLD_FILE $DST_DIR
			((CNT_MOVED++))
		fi
	fi
done
