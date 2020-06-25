#!/bin/bash

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

TIME=$(date '+%d-%m-%y %H:%M:%S');
echo "Starting backup at $TIME"
echo ""

BACKUP_DRIVE="${BACKUP_DRIVE:-/dev/sdc1}"
BACKUP_DRIVE_MOUNT_POINT="${BACKUP_DRIVE_MOUNT_POINT:-/mnt/backup-drive}"

echo "Mounting $BACKUP_DRIVE to $BACKUP_DRIVE_MOUNT_POINT"

exit 0

{
    # Stop containers
    cd /var/rs-root && /usr/local/bin/docker-compose stop

    # Mount USB drive
    umount $BACKUP_DRIVE
    mkdir -p $BACKUP_DRIVE_MOUNT_POINT
    chown $MAIN_USER $BACKUP_DRIVE_MOUNT_POINT
    mount $BACKUP_DRIVE $BACKUP_DRIVE_MOUNT_POINT
    echo "Mounted $BACKUP_DRIVE to $BACKUP_DRIVE_MOUNT_POINT"

    # Sync data
    shopt -s dotglob
    # Rsync won't work in the new setup
    # rsync -ahAP -delete /var/rs-root/ /mnt/backup-drive
    cp -afpruv /var/rs-root $BACKUP_DRIVE_MOUNT_POINT

    # Dump nextcloud
    # Restore: cat your_dump.sql | docker exec -i nextcloud-db psql -U postgres
    /usr/local/bin/docker-compose start nextcloud-db
    docker exec -t nextcloud-db pg_dumpall -c -U $NEXTCLOUD_POSTGRES_DB_USER > $BACKUP_DRIVE_MOUNT_POINT/nextcloud-db_dump.sql

    umount $BACKUP_DRIVE
    echo "Unmounted $BACKUP_DRIVE"

    /usr/local/bin/docker-compose start

    echo ""
    echo "Result: SUCCESS"
    echo "{\"status\":\"SUCCESS\",\"date\":\"$TIME\"}" > /home/birdman/backup.status

} || {
    umount $BACKUP_DRIVE
    echo "Unmounted $BACKUP_DRIVE"

    /usr/local/bin/docker-compose start
    
    echo "Result: ERROR"
    echo "{\"status\":\"ERROR\",\"date\":\"$TIME\"}" > /home/birdman/backup.status
}


echo ""
TIME=$(date '+%d-%m-%y %H:%M:%S');
echo "Backup finished at $TIME"