# pibu  --  Backup-script for raspberry pi

## Introduction:
This is a collection of scripts and files to make make weekbackups from the raspberry pi2 running raspbian
debian jessie latest updates (but it might also work on another systems. I did, however, not tested that).
There is one main script and 4 subscripts. These subscript filenames start with _ and are executed from 
the main script with the source command. The scripts perform the following tasks:
 1. check if this or other scripts are already or still running. Create PIDfile to show that script is busy.
 2. check for available diskspace on 1st backup location.
 3. pause downloads and stop all processes before making backup. Backup named: *weekbackupYYYYWW.tar.gz 201710*
 4. make 1:1 backup and from this make an archive.
 5. check for available diskspace on 2nd backup location.
 6. rename backup for quicker transfer to remote (2nd) backup location.
 7. copy file, filedate same? then copy ok. Rename back to weeknr-format. 
 8. check if all backupfiles are in place, count backupfiles and check weeknrs. Ok? delete 5th week old
 9. resume all downloads and start all processes.
10. delete PIDfile to show that script is succesfully finished.

## Conclusion:
This way every week there will be an archived backup until a maximum of backups defined in variable
*MAXFILES* in the  *makebackup.conf*  file, and one extra copy of the most recent backup-archive on a 2nd location.

## File-list:

|Filename          | Discription                                                                                
| ---------------- | ------------------------------------------------------------------------------------------ 
|README.md         | This file                                                                                  
|makebackup.sh     | Main script. From this shellscript all other scripts are ran and all other information is collected. Main script and subscripts can be run on their own when you uncomment variables.
|makebackup.conf   | All variables and constants are loaded with this file. Change paths to your own situation. There is a lot of information available inside this config-file, please read it.
|_checkpid.sh      | Subscript to make sure mainscript (and therefore subscripts) cannot run more than once at a time. Mainscript checks for native pid (itself) and foreign pid (another script that should not be run simultaniously). 
|_checkspace.sh    | Subscript to check if there is enough space (var *MINSIZE*) available on backup locations first and second. If you want to, you can add a thirth backlocation too.
|_controlproc.sh   | Subscripts that stops processes and pauses downloads and starts processes and resume downloads, defined in array variable *PROCESS* in this subscript. More info: see last lines of * makebackup.conf*
|_checkanddelwk5.sh| Subscript that checks if all backupfiles are in place. If so, then it keeps the max number of backupfiles (var *MAXFILES*) by deleting the first and oldest backupfile. This way you keep having *MAXFILES* nr of backups on the first backuplocation.
|rsync-exclude.txt | In this file all directory-paths are written that rsync has to exclude to leave out of the backupfiles. Certain directories are written to be empty but existend, e.g.  `/mnt`
|startafterr.sh    | After an error occurred, the backupscript halted. When you want to start all processes again you can use this script. Please make sure to delete the backup.pid file yourself!
 
## Paths:

Path                      | Discription
--------------------------|------------------
/home/pi/backupscript     | Directory where all above mentioned files are located by default. Can be changed.
/home/pi/backupscript/log | Directory where all logfiles are stored in format  *backupYYYYMM.log*  Should not be changed.
/                         | Root directory from where the backup will be made, so all information wil be 1:1 copied to first backuplocation
??/backup                 | Directory on first backup location where the copy of `/` will be stored. Only changes will be rsync-ed every time the backupscript will run to reduce time and writecycles. Should not be changed.
??/backuptar              | Directory on first backup location where the compressed (in format *weekbackupYYYYMM.tar.gz*) backupfiles are stored and maintained to the max nr of files (var *MAXFILES*).
??/backuptar              | Directory on 2nd backup location where one compressed backupfile (*weekbackup2ndloc.tar.gz*) is stored. This file is weekly overwritten and only changes are rsync-ed to reduce time and writecycles.       

## Install files on your pi
To aquire the file type the following (from your home directory, cd ~);  
`cd ~`  
`git clone https://github.com/Maikeleg/pibu`  
`mv -T ~/pibu ~/backupscript`  
`cd ~/backupscript`  
`md log`  
`chown -R root ~/backupscript`  
`chmod -R 755 ~/backupscript`  
Ofcourse you can also rename the *pibu* and/or *log* directory to something else, just change the makebackup.conf accordingly.

## Plan to run the script
The main script  *makebackup.sh*  can be planned weekly with a cronjob;  
To edit cron, type:  
`crontab -e`  
Then add the folowing lines in the end, for example to run every Sunday at 9:00 am;  
 
`# m h dom mon dow command`  
`&nbsp;&nbsp;0 9  *   *  Sun /home/pi/backupscript/makebackup.sh`  

## Licence and contact
All files are publicly available under GNU license as open source trough github.
This is my way of giving back to the Linux community.  
You can sent any questions to *maikel dot egberink at gmail dot com*







