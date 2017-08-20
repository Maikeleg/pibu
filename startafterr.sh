#!/bin/bash
#start this script when an error occured, you fixed that, and you want to start all processes again.
#dont forget to delete the pid-file yourself!
YYYYWW=`date +%Y%V`                                 #global variable
LOG="/home/pi/backupscript/log/backup"$YYYYWW".log" #global variable
source _controlproc.sh start
