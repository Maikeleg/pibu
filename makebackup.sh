#!/bin/bash
# crontab every Sunday at 9:00, runtime aprox 20 min
set -o nounset
#This script is the mainscript to make make weekbackups from the raspberry pi. It executes 4 other scripts,
#called subscripts. These subscript filenames start with _ and are executed from this script with the
#source command. The scripts perform the following tasks:
# 1check if this or other scripts are already or still running. Create PIDfile to show that script is busy.
# 2check for available diskspace on 1st backup location.
# 3pause downloads and stop all processes before making backup. backup named: weekbackupYYYYWW.tar.gz 201710
# 4make 1:1 backup and from this make an archive.
# 5check for available diskspace on 2nd backup location.
# 6rename backup for quicker transfer to remote  (2nd) backup location.
# 7copy file, filedate same? then copy ok. Rename back to weeknr-format.
# 8check if all backupfiles are in place, count backupfiles and check weeknrs. Everything ok? delete 5th week old
# 9resume all downloads and start all processes.
#10delete PIDfile to show that script is succesfully closed.
#
#This way every week there will be a archived backup until a maximum of backups defined in Variable MAXFILES in
#the makebackup.conf  file, and one extra copy of the most recent backup-archive on a 2nd location.
#LINENO is env var
#
# Begin script scheduled by cronjob every week on sunday at 09:00am
#
#Variables and constants are defined in the  makebackup.conf  file.
#  !! PLEASE EDIT VARIABLES TO YOUR PERSONAL SITUATION !!
#
#For debug purposes the same variables can be uncommented from here;
#DIRSCRIPT="/home/pi/backupscript/"
#YYYYWW=`date +%Y%V`
#LOG=$DIRSCRIPT"log/backup"$YYYYWW".log"
#PID1="/home/pi/backup.pid"
#PID2="/home/pi/copy.pid"  #foreign process, don't make PIDfile
#DIR1ST="/mnt/download/"
#DIRBU=$DIR1ST"backup/"
#DIRTAR=$DIR1ST"backuptar/"
#DIR2ND
#DIRTAR2="/mnt/dune/DuneHDD_12047e68_6107_418a_b2e0_f641aae95585/backuptar/"
#FILETAR="weekbackup"$YYYYWW".tar.gz"
#FILETAR2="weekbackup2ndloc.tar.gz"
#DATELS1=$(ls $DIRTAR2$FILETAR2 -l --full-time | awk ' { print $6 } ')
#DATELS=`date -d ${DATELS1} +%Y-%m-%d`
#DATENOW=`date +%Y-%m-%d`
#
DIRSCRIPT="/home/pi/backupscript/"
#load all variables from makebackup.conf
STEP="MAIN_VAR"
source $DIRSCRIPT"makebackup.conf"
Catcherror
echo "Step: "$STEP
#this function is used to write specific information in logfile before exiting the mainscript in case of error
#
function Catcherror {
  if [ $? -ne 0 ] #if an error occured
    then
      echo "An error occured at step: "$STEP", Linenumber: "$LINENO". Aborting this script" >> $LOG
      exit 1
  fi
}  #end function Catcherror
#
# begin mainscript
echo "---------------------------------------------------------------------------" >> $LOG
echo "Start backup-log at "`date` >> $LOG
# check if any script is already running (this script didnt stop or another script didnt), if so; abort script
source $DIRSCRIPT"_checkpid.sh" $PID1 native   #check if this script is still running, edit PIDfile
source $DIRSCRIPT"_checkpid.sh" $PID2 foreign  #check but don't make or edit PIDfile because this is a foreign process
# check if enough space is available on 1st backup location
source $DIRSCRIPT"_checkspace.sh" "1st backup location"
# stop all running processes
source $DIRSCRIPT"_controlproc.sh" stop
# Make backup from rootdir, only copy changes and delete files on destination if so, use exlude for certain dirs
echo "---------------------------------------------------------------------------" >> $LOG
echo "Start making incremental backup at "`date` >> $LOG
STEP="MAIN_RSYNC_INC_BACKUP"
sudo rsync --archive --hard-links --itemize-changes --delete-during --exclude-from=$DIRSCRIPT"rsync-exclude.txt" --log-file=$LOG / $DIRBU
Catcherror
echo "Step: "$STEP
# make new tarfile from current backup e.g.:  weekbackup201709.tar.gz
echo "---------------------------------------------------------------------------" >> $LOG
echo "Start making tarfile from backup at "`date` >> $LOG
STEP="MAIN_TAR_FROM_BACKUP"
#sudo tar --gzip --create --verbose --verbose --file=$DIRTAR$FILETAR /mnt/download/backup/ >> $LOG 2>&1 #redirect stdout and stderr to file
#zip tar with pigz for using all (4) cpu-cores when compressing
sudo sh -c "tar --create --verbose --verbose $DIRBU | pigz > $DIRTAR$FILETAR" >> $LOG 2>&1 #redirect stdout and stderr to file
Catcherror
echo "Step: "$STEP
# check if enough space is available on 2nd backup location
source $DIRSCRIPT"_checkspace.sh" "2nd backup location"
# rename fresh backup to FILETAR2 so only blockchanges are transfered
echo "---------------------------------------------------------------------------" >> $LOG
echo "Renaming file to" $FILETAR2 "to effectively transfer file to 2nd backup location at" >> $LOG
echo `date` >> $LOG
STEP="MAIN_RENAME_TO_BACKUP2nd"
mv --verbose $DIRTAR$FILETAR $DIRTAR$FILETAR2 >> $LOG 2>&1 #redirect stdout and stderr to file
Catcherror
echo "Step: "$STEP
# copy backuptar FILETAR2 to 2nd backup location
echo "---------------------------------------------------------------------------" >> $LOG
echo "Start copying tarfile to 2nd backup location at "`date` >> $LOG
STEP="MAIN_COPY_TAR_TO_BACKUP2"
sudo rsync --archive --itemize-changes --log-file=$LOG $DIRTAR$FILETAR2 $DIRTAR2$FILETAR2
Catcherror
echo "Step: "$STEP
# check if transferred file to 2nd backup location has today's date
echo "---------------------------------------------------------------------------" >> $LOG
echo "Check if transferred file to 2nd backup location has todays date; " $DATENOW >> $LOG
echo "Is this date the same as the file at 1st backup location;         " $DATELS >> $LOG
echo "Checking..." >> $LOG
STEP="MAIN_IFTHEN_FILEDATE"
if [ "$DATELS" == "$DATENOW" ] #check filedate on 2nd backup location with current filedate
then
  echo $FILETAR2 "is correctly transfered to 2nd backup location, filedate correct." >> $LOG
else
  echo $FILETAR2 "is NOT correctly transfered, please investigate!!" >> $LOG
fi
Catcherror
echo "Step: "$STEP
echo "Renaming file back to" $FILETAR":" >> $LOG
STEP="MAIN_RENAME_TO_weekbackupXXXXXX"
mv --verbose $DIRTAR$FILETAR2 $DIRTAR$FILETAR >> $LOG 2>&1 #redirect stdout and stderr to file #rename back
Catcherror
echo "Step: "$STEP
# check backup tarfiles and delete 5th (in case MAXFILES=4) week old backupfile when everything is ok
source $DIRSCRIPT"_checkanddelwk5.sh"
# start all processes again
source $DIRSCRIPT"_controlproc.sh" start
# remove PID file after succesfull run
STEP="MAIN_REMOVE_PID"
rm -f $PID1 >> $LOG 2>&1 #redirect stdout and stderr to file
Catcherror
echo "Step: "$STEP
echo "PIDfile "$PID1" removed after end of native script" >> $LOG
echo "End backup-log at "`date` >> $LOG
echo "---------------------------------------------------------------------------" >> $LOG
# End mainscript
