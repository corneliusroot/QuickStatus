#!/bin/bash
#-------------------------------------------------------
#Quick Status v3
#
#
#Usage: bash quickstatus 
# -q for quiet mode
# make the second argument "test" to test alerts
# e.g. "quickstatus 1 test"
# for cron jobs use
#    */10 * * * * /usr/local/bin/quickstatus -q
# add to .bash_profile to get a quick status when you log in
#-------------------------------------------------------
# V3 Changelog 12-29-21
# Added 
#  - Notification via ntfy.sh
#  - Add headless run for crons (-q)
#  - Add CPU load monitoring 
# Bugfixes 
#  - changed lsof based checks to look for LISTEN rather than service name to resolve false alarms
# 
# TODO
# Add restart capabilities

#### CONFIGURATION
#Set LSOF to your local environment
lsof="/usr/sbin/lsof"
ntfysub="Your_ntfy.sh_subscription_name"

# Set colors for red/grn/yel text
red='\e[0;31m'
grn='\e[0;32m'
yel='\e[0;93m'
NC='\e[0m' # No Color

#Force alerts by setting to any value
if [ "$2" == "test" ]
        then
                teststatus="1"
        else
                teststatus="0"
fi

#define a notification method
function notifycmd {
curl --silent -d "$(hostname) $alert" ntfy.sh/$ntfysub >/dev/null
}

#configure verbose and quite modes
if [ "$1" = "-q" ]
        then
                verbose="true" 
                printfverbose="true" 
        else
                verbose="echo -e"
                printfverbose="printf"
fi


#Set the alert message to none
alert=""

#Get uptime and reformat it to something easy to read
uptime=$(uptime -p | sed 's/^up //')

#check the 15 minute CPU load
#configured for a 2 core VPS. Adjust values as needed
check15m (){
#configure load thresholds for your own server. 
okload=2.99 #load is okay if it's lower than this
warnload=2.99 #load is warning if higher than this but lower than highload
highload=4 #load is considered to be too high after this point

cpu15mload=$(top -b -n1 | head -1 | awk '{ print $NF }')
if (( $(echo "$cpu15mload $okload" | awk '{print ($1 < $2)}') ));
        then
                cpuload="${grn}${cpu15mload}${NC}"
                        if [ $teststatus == 1 ]
                        then
                        alert="$alert CPU15-$cpu15mload"
                        fi
        else
                if (( $(echo "$cpu15mload $highload" | awk '{print ($1 > $2)}') ));
                        then
                        cpuload="${red}${cpu15mload}${NC}"
                        alert="$alert CPU15-$cpu15mload"
                                then
                                        cpuload="${yel}${cpuload}${NC}"
                                else true
                        fi
                fi
fi
}

###### File System Check function
checkfs (){
#get list of file systems
filesystems=$(df -P | grep ^/ |sed -e '/^none/d' -e '/^Filesystem/d' -e 's#^/#@,/#g' | awk '{ print $1","$5","$6 }')

#Define the name of the file we're going to use for a read-only check
touchfile=".$(date +%N).qd"
$verbose  "Partition        Use Mountpoint            Status       CAPACITY      INODES"

#Loop for checking each file system for fullness and writeability
for fs in $(echo $filesystems| grep @)
do
partition=$(echo $fs | cut -d, -f2)
percentfull=$(echo $fs | cut -d, -f3 | sed 's/%//')
mountpoint=$(echo $fs | cut -d, -f4)
inodefull=$(df -P -i | grep $partition| grep ^/ |sed -e '/^none/d' -e '/^Filesystem/d' -e 's#^/#@,/#g' | awk '{ print $5 }'| cut -d% -f1)

touch $mountpoint/$touchfile >/dev/null 2>&1
if [ -f $mountpoint/$touchfile ]
        then
                writeable=" Writeable "
                rm -f $mountpoint/$touchfile
                fsw=$grn
                if [ $teststatus == 1 ]
                        then
                        alert="$alert $partition_RO"
                fi
        else
                writeable=" READ ONLY "
                fsw=$red
                alert="$alert $partition_RO"
fi

if test ${percentfull} -le 89
        then
                capwarn="    OK    "
                capco=$grn
                                if [ $teststatus == 1 ]
                                        then
                                        alert="$alert $partition CRIT99"
                                fi
        else
                if test $percentfull -ge 99
                        then
                                capwarn=" CRITICAL "
                                capco=$red
                                alert="$alert $parition CRIT99"
                        else
                        if test $percentfull -ge 90
                                then
                                        capwarn="   WARN   "
                                        capco=$yel
                                else true
                        fi
                fi
fi



if test ${inodefull} -le 89
        then
                inodewarn="    OK    "
                inodeco=$grn
                                if [ $teststatus == 1 ]
                                        then
                                        alert="$alert $partition INODE99"
                                fi
        else
                if test $inodefull -ge 99
                        then
                                inodewarn=" CRITICAL "
                                inodeco=$red
                                                                alert="$alert $partition INODE99"
                        else
                        if test $inodefull -ge 90
                                then
                                        inodewarn="   WARN   "
                                        inodeco=$yel
                                else true
                        fi
                fi
fi

$printfverbose "%-15s ${capco}%3s%%${NC} %-18s [${fsw}%-10s${NC}] [${capco}%10s${NC}] [${inodeco}%10s${NC}]\n" "${partition}" "${percentfull}" "${mountpoint}" "${writeable}" "${capwarn}" "${inodewarn}"

done
}
########### END File system checking




########## BEGIN Web Services checking
checkweb (){
# The same structure is used for all checks. Use LSOF to make sure the assigned port is listening. No further comments on this.
port80=$($lsof -i:80 |  grep LISTEN | tail -1 | awk '{ print $NF }' | tr -d \(\))
if [  $port80 = "LISTEN" ]
        then
                                status80="${grn}Apache OK${NC}"
                                if [ $teststatus == 1 ]
                                        then
                                        alert="$alert APACHE"
                                fi
        else
                status80="${red}WEB SERVER OFFLINE${NC}"
                                alert="$alert APACHE"
fi
}

##### Function: Postfix queue check
#can be modified for Exim or other MTA's
ebpc=$(mailq | tail -1 | awk '{ print $5 }')
if [ -z $ebpc ]
        then
        cebpc="${grn}Empty${NC}"
                                                                if [ $teststatus == 1 ]
                                                                        then
                                                                        alert="$alert MAILQ"
                                                                fi

        else
                if test ${ebpc} -le 1999
                        then
                                cebpc="${grn}${ebpc}${NC}"
                                                                if [ $teststatus == 1 ]
                                                                        then
                                                                        alert="$alert MAILQ"
                                                                fi
                        else
                        cebpc="${red}${ebpc}${NC}"
                                                alert="$alert MAILQ_$ebpc"
                fi
fi
##### End Function: Postfix queue check
# SQL Server check
if [ "$($lsof -i:3306 |  grep LISTEN | tail -1 | awk '{ print $NF }' | tr -d \(\))" == "LISTEN" ]
        then
                cmysql="${grn}MySQL OK${NC}"
                                                                if [ $teststatus == 1 ]
                                                                then
                                                                alert="$alert SQL"
                                                                fi

        else
                cmysql="${red}MySQL DOWN${NC}"
                                alert="$alert SQL"

fi

#Dovecot check
if [ "$($lsof -i:110 | awk '{ print $1}' | tail -1)" == "dovecot" ]
        then
                cdovecot="${grn}Dovecot OK${NC}"
                                                                if [ $teststatus == 1 ]
                                                                then
                                                                alert="$alert DOVECOT"
                                                                fi

        else
                cdovecot="${red}Dovecot DOWN${NC}"
                                alert="$alert DOVECOT"

fi

# Postfix status check
if [ "$($lsof -i:25 |  grep LISTEN | tail -1 | awk '{ print $NF }' | tr -d \(\))" == "LISTEN" ]
        then
                cpostfix="${grn}Postfix OK${NC}"
                                                                if [ $teststatus == 1 ]
                                                                then
                                                                alert="$alert POSTFIX"
                                                                fi

        else
                cpostfix="${red}Postfix DOWN${NC}"
                                alert="$alert POSTFIX"
fi
# Begin displaying output
$verbose "--------------------------------"
$verbose "Hostname      "$(hostname)
$verbose "Uptime:       "${uptime}
check15m
$verbose "15m CPU Load: "${cpuload}
checkweb
$verbose "MySQL:        "${cmysql}
$verbose "Postfix:      "${cpostfix}
$verbose "Dovecot:      "${cdovecot}
$verbose "Mail Queue:   "${cebpc}
$verbose "--------------------------------"
checkfs

# If there is an alert message, send it. Otherwise do nothing.
if [ -n "$alert" ]
then
notifycmd
#echo $alert
fi
