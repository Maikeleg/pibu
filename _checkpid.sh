#!/bin/bash
#set +o errexit  #explicitly dont exit on errors in this script, because thats how the script works
set -o nounset
#This subscript keeps a PID file with the current PID processid to protect from the same script running double
#It first checks if its a check on the native (own) proces $2 or if the check is on a foreign process
#(e.g.:copycript, $2). This is because on a foreign process you cannot add the current PID to the foreign file
#execute bit off: this subscript is being executed with source command by mainscript makebackup.sh
#the following variables can be uncommented to run this subscript standalone for debug purposes. You must
#also set script chown and chmod;
#YYYYWW=`date +%Y%V`                                 #global variable
#LOG="/home/pi/backupscript/log/backup"$YYYYWW".log" #global variable
#
PIDFILE=$1                       #first scriptparameter e.g.: backup.pid, copy.pid
PROCESS=$2                       #second scriptparameter e.g.: native, foreign
# begin subscript
echo "Step: _CHKPID $2"
echo "--------------------------------------------------------------------" >> $LOG
echo "Checking if scripts are still/already running at "`date`"..." >> $LOG
if [ "$PROCESS" = "foreign" ]    #foreign process, don't make PIDfile
then
  if [ -f $PIDFILE ]             #if PID file is found
  then
    PID=$(cat $PIDFILE)          #read PID file
    ps -p $PID > /dev/null 2>&1  #look if process exists with PID
    if [ $? -eq 0 ]              #result from ps, $?=0, no error from ps, process already running, abort script
    then
      echo "PIDfile "$1" is found, process with PID: "$PID" is already running." >> $LOG
      echo "Aborting this script" >> $LOG
      exit 1                     #exit to terminal
    else                         #Process not found assume not running. Everything OK
      echo "PIDfile "$1" is found, process with PID: "$PID" is not running. OK" >> $LOG
      echo "PIDfile of this foreign process not changed" >> $LOG
    fi
  else                           #if PID file is not found
    echo "PIDfile "$1" is not found. OK" >> $LOG
  fi
elif [ "$PROCESS" = "native" ]   #native (own) process, make PIDfile
then
  if [ -f $PIDFILE ]             #if PID file is found
  then
    PID=$(cat $PIDFILE)          #read PID file
    ps -p $PID > /dev/null 2>&1  #look if process exists with PID
    if [ $? -eq 0 ]              #result from ps, $?=0, no error from ps, process already running, abort script
    then
      echo "PIDfile "$1" is found, process with PID: "$PID" is already running." >> $LOG
      echo "Aborting this script" >> $LOG
      exit 1                     #exit to terminal
    else                         #Process not found assume not running. Everything OK
      echo $$ > $PIDFILE         #create or add new value in PID file with PID of main running script
      if [ $? -ne 0 ]            #error, file cannot be created (error not 0)
      then
        echo "PIDfile "$1" is found, process wit PID: "$PID" is not running. OK" >> $LOG
        echo "Could not put current Process-id (PID) in PID file, aborting this script" >> $LOG
        exit 1                   #exit to terminal
      else
        echo "PIDfile "$1" is found, process with PID: "$PID" is not running. OK" >> $LOG
        echo "Current Process-id (PID) is succesfully inserted in PIDfile "$1" on "`date` >> $LOG
      fi
    fi
  else                           #if PID file is not found
    echo $$ > $PIDFILE           #create PID file with PID of main running script
    if [ $? -ne 0 ]              #if cannot create PID file, error not 0
    then
      echo "PIDfile "$1" not found, could not create PID file, aborting this script" >> $LOG
      exit 1                     #exit to terminal
    else
      echo "PIDfile "$1" is not found. OK" >> $LOG
      echo "Current Process-id (PID) is succesfully inserted in PIDfile "$1" on "`date` >> $LOG
    fi
  fi
fi
# end subscript
