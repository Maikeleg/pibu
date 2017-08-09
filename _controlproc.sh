#!/bin/bash
#set -o errexit
set -o nounset
#This subscript can stop or start all processes. This script is run from the mainscriot with parameter stop
#or start, e.g: _controlproc stop
#function Linespace fills up a line with the number of spaces provided as a parameter $1
#function Givestatus gives the status of a daemon service. It's run before and after stopping/starting all services.
#function Controlservice is used to start or stop a daemon service
#The main program consists of a way to detect the start or stop parameter. It then runs a loop to stop all
#services declared in array PROCESS. Starting services means running the loop backwards.
#Downloads are paused before stopping services and resumed after starting services for sabnzbd and transmission
#execute bit off: this subscript is being executed with source command by mainscript makebackup.sh
#the following variables can be uncommented to run this subscript standalone for debug purposes.
#You must also set script chown and chmod;
#YYYYWW=`date +%Y%V`                                 #global variable
#LOG="/home/pi/backupscript/log/backup"$YYYYWW".log" #global variable
declare -a PROCESS=(lighttpd mpd sabnzbdplus transmission-daemon plexmediaserver)
function Linespace {
	local COUNT=0                #every loop start to count from 0
        local NR=$1                  #$1 is function parameter 1, nr of spaces on a line
	while [ $COUNT -le $NR ]     #while 0 less than nr of filling soaces
	do
	  echo -n " " >> $LOG        #put nr of fillingspaces calculated with $SPACES
	  COUNT=$(( $COUNT + 1 ))    #inc COUNT
	done
} #end function Linespace
function Givestatus {
        local ID=$1                                 #$1 is function parameter 1
	local SPACES=$((20 - ${#PROCESS["$ID"]} ))  #calc max length 20 characters - nr of characters of processname=fillingspaces
	echo -n ${PROCESS["$ID"]} "status:" >> $LOG #echo processname
	Linespace $SPACES
        STEP="_CONTRPROC_FUNC_SERVICE_STATUS"
	sudo service ${PROCESS["$ID"]} status | grep "Active: " >> $LOG 2>&1 #redirect stdout and stderr to file #write status of process behind "status:"
	Catcherror
        echo "Step: "$STEP
} #end function Status
function Controlservice {
        local ID=$1                                 #$1 is function parameter 1
        local CONTROL=$2                            #$2 is function parameter 2, e.g.: start
        STEP="_CONTRPROC_FUNC_SERVICE_STST"
	sudo service ${PROCESS["$ID"]} $CONTROL >> $LOG 2>&1 #redirect stdout and stderr to file  #start or stop service
	Catcherror
        echo "Step: "$STEP
} #end function Controlservice
function Catcherror {
	if [ $? -ne 0 ] #if an error occured
	  then
	    echo -n "An error occured at step: "$STEP", Linenumber: "$LINENO". Aborting this script" >> $LOG
	    exit 1
	fi
} #end function Catcherror
#
#begin subscript
echo "---------------------------------------------------------------------------" >> $LOG
if [ "$1" = "stop" ] #this $1 is scriptvariable $1
#stop all processes
then
  sudo service sabnzbdplus start #specifically in the case when sabnzbd stopped in a previous instance of this script so curl is not going to trow an error
  STEP="_CONTRPROC_CURL_PAUSE"
  echo "sabnzbd returns: " >> $LOG
#please change to your own apikey:
  curl "http://192.168.1.49:9090/sabnzbd/api?mode=pause&apikey=a5260687af2fffff6fba22a15b1b4457" >> $LOG 2>&1 #redirect stdout and stderr to file
  Catcherror
  echo "Step: "$STEP
  echo "paused all jobs for sabnzbd" >> $LOG
  sudo service transmission-daemon start #specifically in the case when transmission stopped in a previous instance of this script so remote is not going to trow an error
  STEP="_CONTRPROC_TRANS_REM_STOP"
  echo "transmission daemon returns: " >> $LOG
  transmission-remote -t all --stop >> $LOG 2>&1 #redirect stdout and stderr to file
  Catcherror
  echo "Step: "$STEP
  echo "paused all jobs for transmission" >> $LOG
  echo "Stop all running processes at "`date` " now:" >> $LOG
  for N in {0..4}  #5 processes in array
  do
    Givestatus $N
    Controlservice $N stop
    Givestatus $N
  done
  echo "All processes stopped for a silent system at "`date` >> $LOG
elif [ "$1" = "start" ] #this $1 is scriptvaiable $1
#start all processes
then
  echo "Start all running processes at "`date` " now:" >> $LOG
  for N in {4..0}  #5 processes in array
  do
    Givestatus $N
    Controlservice $N start
    Givestatus $N
  done
  STEP="_CONTRPROC_CURL_RESUME"
  echo "sabnzbd returns: " >> $LOG
#please change to your own apikey:
  curl "http://192.168.1.49:9090/sabnzbd/api?mode=resume&apikey=a5260687af2fffff6fba22a15b1b4457" >> $LOG 2>&1 #redirect stdout and stderr to file
  Catcherror
  echo "Step: "$STEP
  echo "resumed all jobs for sabnzbd" >> $LOG
  STEP="_CONTRPROC_TRANS_REM_START"
  echo "transmission daemon returns: " >> $LOG
  transmission-remote -t all --start >> $LOG 2>&1 #redirect stdout and stderr to file
  Catcherror
  echo "Step: "$STEP
  echo "resumed all jobs for transmission" >> $LOG
  echo "All processes started again at "`date` >> $LOG
else
#  echo "no correct scriptparameter, only  start  or  stop  are allowed" #error when called on commandline
  exit 1
fi
#end subscript
