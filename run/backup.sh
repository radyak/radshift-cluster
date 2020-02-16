#!/bin/bash

TIME=$(date '+%d-%m-%y %H:%M:%S');
echo "Starting backup at $TIME"
echo ""

{
    cd /var/rs-root && docker-compose stop

    sudo mkdir -p /mnt/backup-usb-drive
    sudo mount /dev/sdb /mnt/backup-usb-drive
    # confirm with lsblk -> sdb           8:16   0 232.9G  0 disk /mnt/backup-usb-drive
    shopt -s dotglob
    sudo rsync -avhAP -delete /var/rs-root/ /mnt/backup-usb-drive
    sudo umount /dev/sdb

    cd /var/rs-root && docker-compose start

    echo ""
    echo "Result: SUCCESS"
    echo "{\"status\":\"SUCCESS\",\"date\":\"$TIME\"}" > ./backup.status

} || {
    cd /var/rs-root && docker-compose start
    echo "Result: ERROR"
    echo "{\"status\":\"ERROR\",\"date\":\"$TIME\"}" > ./backup.status
}


echo ""
TIME=$(date '+%d-%m-%y %H:%M:%S');
echo "Backup finished at $TIME"