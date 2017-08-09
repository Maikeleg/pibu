#!/bin/bash
#set -o errexit #explicitly exit on errors in this script
set -o nounset
#This subscript checks if there is enough diskspace available on the disk given trough scriptparameter $1
#totalfilesize=$(find . -type f -printf "%s + " | dc -e0 -f- -ep)
#execute bit off: this subscript is being executed with source command by mainscript makebackup.sh
#the following variables can be uncommented to run this subscript standalone for debug purposes.
#You must also set script chown and chmod;
#YYYYWW=`date +%Y%V`                                 #global variable
#LOG="/home/pi/backupscript/log/backup"$YYYYWW".log" #global variable
#
function Catcherror {
  if [ $? -ne 0 ] #if an error occured
    then
      echo -n "An error occured at step: "$STEP", Linenumber: "$LINENO". Aborting this script" >> $LOG
      exit 1
  fi
}  #end function Catcherror
STEP="_CHCKSPACE_VAR_1STBACKUP"
#variables 1STBU and 2NDBU are defined here to get the most recent values
AVAIL1=$(df -k $DIR1ST | tail -1 | awk '{print $4}') #Available 1st backup
Catcherror
echo "Step: "$STEP
STEP="_CHCKSPACE_VAR_2NDBACKUP"
AVAIL2=$(df -k $DIR2ND | tail -1 | awk '{print $4}') #Available 2nd backup
Catcherror
echo "Step: "$STEP
#please define variable MINSIZE for min available disksize in makebackup.conf file
#MINSIZE=2560  #2,5GB in kB
DISK=$1       #scriptparameter
# begin subscript
echo "---------------------------------------------------------------------------" >> $LOG
echo "Checking disksize on disk "$DISK" at "`date`"..." >> $LOG
if [ "$DISK" = "1st backup location" ]
then
  if [ $AVAIL1 -lt $MINSIZE ] #less than
  then
    echo "NOT enough space available for copy on $DISK , exiting and aborting script! on "`date` >> $LOG
    exit 1
  else
   echo "Enough space available on $DISK" >> $LOG
  fi
elif [ "$DISK" = "2nd backup location" ]
then
  if [ $AVAIL2 -lt $MINSIZE ] #less than
  then
    echo "NOT enough space available for copy on $DISK , exiting and aborting script" >> $LOG
    exit 1
  else
    echo "Enough space available on $DISK" >> $LOG
  fi
else
    echo "No or incorrect parameter 1 given, abort script"
fi
#end subscript
