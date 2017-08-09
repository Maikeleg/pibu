#!/bin/bash
set -o nounset
#This subscript first checks if all backupfiles are in place. According to this analysis it updates the logfile
#and the script decides what to do. In the constant variable MAXFILES you put the number of backupfiles you
#want to keep. If there are less backupfiles in place, probably you just started to run the script.
#If there are more backupfiles in place, something went wrong and no oldest backupfile is deleted. This will
#happen in the beginning of the year; e.g: FILECALC=201801-4=201797, but the filenames will not match so
#no file will be deleted until in the 5th new week of the year it will work again: 201805-4=201801
#If there are 5 files detected and 4 expected, the oldest file will be deleted.
#if there are 4 files detected and 4 expected, the oldest file is already deleted and everything is in place.
#if there are 4 files detected and 4 expected AND there is an error ($ERROR>0) there will be no files deleted
#execute bit off: this subscript is being executed with source command by mainscript makebackup.sh
#the following variables can be uncommented to run this subscript standalone for debug purposes. You must
#also set script chown and chmod;
#YYYYWW=`date +%Y%V`                                 #global variable
#LOG="/home/pi/backupscript/log/backup"$YYYYWW".log" #global variable
#DIRTAR="/mnt/download/backuptar/"                   #global variable
#SEARCH="weekbackup*"                                #global variable
NRFILES=$(ls $DIRTAR$SEARCH -1 | wc -l)
ERROR=0
# Please change MAXFILES to the number of backupfiles you want to keep in makebackup.conf file
#MAXFILES=4                                          #global variable
#
function Catcherror {
  if [ $? -ne 0 ] #if an error occured
    then
      echo "An error occured at step: "$STEP", Linenumber: "$LINENO". Aborting this script" >> $LOG
      exit 1
  fi
}  #end function Catcherror
#begin subscript
echo "--------------------------------------------------------------------" >> $LOG
# check if all supposed to be backupfiles are actually there
STEPC=1                          #start counting from first file
MAXCOUNT=$((NRFILES+1))          #count until all files counted (NRFILES) plus 1 more which is new backupfile
echo "Checking if all weekbackup-archives are there at "`date`"..." >> $LOG
STEP="_CHCKWK5_WHILEDO_SCAN_FILES"
while [[ $STEPC -lt $MAXCOUNT ]] #step $STEPC (1,2,3...) until $MAXCOUNT (nr of files+1)
  do
    FILECALC="${DIRTAR}weekbackup`expr $YYYYWW - $NRFILES + $STEPC`.tar.gz" #e.g.: 201710-5+1, 201710-5+2, 201710-5+3
    echo "calculated: " $FILECALC >> $LOG                                   #calculate expected filename
    FILELS="$(ls $DIRTAR$SEARCH -1 | tail -n +$STEPC | head -1)"            #use tail+head to focus on 1st,2nd,3rd,etc file
    echo "List:       " $FILELS >> $LOG                                     #list actual filename
    if [ "$FILECALC" = "$FILELS" ]
    then
      echo "   The supposed file " $FILECALC " is detected, OK" >> $LOG
    else
      echo "   The supposed file " $FILECALC " is NOT detected, instead file " $FILELS " is detected" >> $LOG
      ERROR=$((ERROR+1))   #increment ERROR if there is
    fi
    STEPC=$((STEPC+1))     #increment STEP every while-do
done
Catcherror
echo "Step: "$STEP
echo "The maximum allowed weekbackupfiles is set to" $MAXFILES". There are " $NRFILES " weekbackups detected" >> $LOG

MAXCALC=$((MAXFILES+1))    #include this weeks backupfile, so MAXCALC = MAXFILES+just created backupfile
# when no errors occured delete the backup made 5 weeks ago (so there always will be 4 weeks of backupfiles)
if [ $ERROR -eq 0 ]
then
  echo "No errors occured, all previous weekbackupfiles are in place" >> $LOG
  if [ $NRFILES -eq $MAXCALC ]      #if all expected files are in place
  then
    FILEDEL="${DIRTAR}weekbackup`expr $YYYYWW - $MAXFILES`.tar.gz" #e.g: 201710-4=201706
    STEP="_CHCKWK5_REMOVE_WK5"
    rm --force --preserve-root --verbose $FILEDEL >> $LOG 2>&1
    Catcherror
    echo "Step: "$STEP
    echo "The oldest weekbackup, made "`expr $MAXFILES + 1`" weeks ago; " $FILEDEL " is deleted" >> $LOG
  elif [ $NRFILES -lt $MAXCALC ]    #if there are less files then expected (incl oldest backupfile)
  then
    if [ $NRFILES -lt $MAXFILES ]   #if there are less files than expected
    then
      echo "Because there are not yet" $MAXFILES "weeks of weekbackups, but" $NRFILES", there will be no weekbackupfile deleted" >> $LOG
      echo "Step: _CHKWK5_NOTREMOVED_LESSWK"
    elif [ $NRFILES -eq $MAXFILES ] #if there are exactly the right amount of files (oldest backupfile already deleted)
    then
      echo "All backupfiles are up-to-date and in place" >> $LOG
    fi
  elif [ $NRFILES -gt $MAXCALC ]    #if there are more files then expected
  then
    echo "Because there are more than" $MAXFILES "weeks of weekbackups, there will be no backupfile(s) deleted, please delete manually and investigate!!" >> $LOG
    echo "Step: _CHKWK5_NOTREMOVED_MOREWK"
    return
  fi
else #if there are errors counted (ERROR <> 0)
  STEP="_CHCKWK5_ERRORS_COUNT_BACKUPFILES"
  Catcherror
  echo "Step: "$STEP
  echo "$ERROR errors occured, NOT all backupfiles are in place, PLEASE CHECK !! The oldest backupfile was NOT deleted !" >> $LOG
fi
#end subscript
