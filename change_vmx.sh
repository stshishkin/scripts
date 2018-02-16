#!/bin/sh
#
# USAGE: $0 /absolute/path/to/file.iso
# Changes cdrom settings in vmx file. Replaces just cdrom drive's options. Other options remain unchanged. 
# Backups old vmx file at the same folder with .bak extension  
#

FILENAME=$1
VMX_FILE=/vmfs/volumes/datastore1/1.vmx

ISO_PARAMS=$(cat << EOF
ide1:0.deviceType = "cdrom-image"
ide1:0.fileName = "$FILENAME"
ide1:0.present = "TRUE"
EOF
)

if grep -q $FILENAME $VMX_FILE ; then
    echo "Ready to power up"
    exit 0
else
    echo "Settings were changed!"
    echo "Fixing..."
    ide=$(grep cdrom $VMX_FILE | cut -d. -f1)
    num=$(grep -n "$ide" $VMX_FILE | head -1 | cut -d: -f1)
    sed -i.bak "/$ide/d" $VMX_FILE 
    sed "${num}i${ISO_PARAMS}" $VMX_FILE 
    exit 0          
fi             
