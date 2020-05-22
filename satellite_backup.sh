#################################################################
# Creation date: 2020-05-18
# Author: Frank Reimer
# 
# Tested on Satellite version:
# - 6.6
#
# Description:
# ------------
# This script creates a Satellite backup in offline mode with all 
# the Satellite configurations, certificates and Pulp data. This 
# means that the Satellite services are unavailable during the
# backup process. This ensures a consistent backup of your data.
# Please keep this in mind and schedule your Satellite backup at
# a time where Satellite service unavailability is not a problem.
# Backups older than MAX_DAYS will be deleted automatically.
# Use this script on your own risk!!! I don't guarantee for any 
# functionalities. Please test this script in a proper test
# environment first if you are unsure of using this script.
#
# Parameters you need to change according to your needs:
# - BACKUP_MOUNT        -> You need a dedicated mount point to
#                          store your backups.
# - BACKUP_DESTINATION  -> The folder where you want to store 
#                          your backups (e.g. the hostname)
# - MAX_DAYS            -> The time before the script starts 
#                          deleteing backups older MAY_DAYS
# - FULL_BACKUP_WEEKDAY -> The weekday when the full backup
#                          should be created. Default is Sat.
#################################################################
#!/bin/bash -e
PATH=/sbin:/bin:/usr/sbin:/usr/bin
BACKUP_MOUNT=/backup/mountpoint
BACKUP_DESTINATION=$BACKUP_MOUNT/backup_path
LOG_PATH=/var/log/satellite_backup_log
LOG_FILE=$LOG_PATH/satellite-backup.log
DATE=$(date "+%Y%m%d-%H%M")
MAX_DAYS=15
FULL_BACKUP_WEEKDAY=6

# Create Backup log destination folder
if [[ ! -e $LOG_PATH ]]; then
    mkdir -p $LOG_PATH
elif [[ ! -d $LOG_PATH ]]; then
    echo "$LOG_PATH already exists but is not a directory!" 1>&2
    exit 1
fi

DATE_MOUNT=$(date "+%Y-%m-%d %H:%M:%S")
# Check if BACKUP_MOUNT is mounted
if ! grep $BACKUP_MOUNT /proc/mounts; then
  echo "$DATE_MOUNT: INFO: $BACKUP_MOUNT is not mounted. Try to mount it now." >> $LOG_FILE
  if ! mount $BACKUP_MOUNT; then
    echo "$DATE_MOUNT: ERROR: Backup mountpoint $BACKUP_MOUNT could not be mounted." >> $LOG_FILE
    exit 1
  else
    echo "$DATE_MOUNT: SUCCESS: $BACKUP_MOUNT successfully mounted." >> $LOG_FILE
  fi
fi

# Create backup destination folder
if [[ ! -e $BACKUP_DESTINATION ]]; then
    mkdir -p $BACKUP_DESTINATION
elif [[ ! -d $BACKUP_DESTINATION ]]; then
    echo "$DATE_MOUNT: ERROR: $BACKUP_DESTINATION already exists but is not a directory!" >> $LOG_FILE
    exit 1
fi

# Delete backups older $MAX_DAYS
DATE_DELETE=$(date "+%Y-%m-%d %H:%M:%S")
find $BACKUP_DESTINATION/* -type d -mtime +$MAX_DAYS -prune -exec bash -c "echo $DATE_DELETE: INFO: Delete backup {} >> $LOG_FILE; rm -rf {}" \;

# Create full backup on weekday 6 (Saturday), else create incremental backup and use $LAST incremental backup as source.
if [[ $(date +%w) == $ $FULL_BACKUP_WEEKDAY ]]; then
  DATE_START=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$DATA_START: INFO: Full backup $BACKUP_DESTINATION/satellite-backup-$DATE-full started." >> $LOG_FILE
  satellite-maintain backup offline --assumeyes --preserve-directory $BACKUP_DESTINATION/satellite-backup-$DATE-full-$(date +%w)
  if [ $? -eq 0 ]; then
    DATE_FINISHED=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$DATE_FINISHED: SUCCESS: Full backup $BACKUP_DESTINATION/satellite-backup-$DATE-full-$(date +%w) created." >> $LOG_FILE
  else
    DATE_FINISHED=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$DATE_FINISHED: ERROR: Full backup $BACKUP_DESTINATION/satellite-backup-$DATE-full-$(date +%w) could not be created. Please verify." >> $LOG_FILE
  fi
else
  LAST=$(ls -td -- $BACKUP_DESTINATION/*/*/ | head -n 1)
  DATE_START=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$DATE_START: INFO: Incremental backup $BACKUP_DESTINATION/satellite-backup-$DATE-incremental-$(date +%w) started." >> $LOG_FILE
  satellite-maintain backup offline --assumeyes --incremental "$LAST" $BACKUP_DESTINATION/satellite-backup-$DATE-incremental-$(date +%w)
  if [ $? -eq 0 ]; then
    DATE_FINISHED=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$DATE_FINISHED: SUCCESS: Incremental backup $BACKUP_DESTINATION/satellite-backup-$DATE-incremental-$(date +%w) created." >> $LOG_FILE
  else
    DATE_FINISHED=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$DATE_FINISHED: ERROR: Incremental backup $BACKUP_DESTINATION/satellite-backup-$DATE-incremental-$(date +%w) could not be created. Please verify." >> $LOG_FILE
  fi
fi
exit 0