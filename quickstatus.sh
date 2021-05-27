#!/bin/sh
#-------------------------------------------------------
#Quick Diag v.2
#Created by Ryan Flowers for ASO 9/30/2014
#Please report all bugs to ryan.flowers@asmallorange.com
#Please include server details and account details so
#that I can reproduce the problem.
#
#
#Usage: sh quickdiag.sh
# 05/26/21 Added dovecot on port 110 and Postfix on 25
#-------------------------------------------------------



# Getting all colorful for this one
red='\e[0;31m'
grn='\e[0;32m'
yel='\e[0;93m'
NC='\e[0m' # No Color

#Get uptime and reformat it to something easy to read
uptime=$(uptime -p | sed 's/^up //')

###### File System Check function
checkfs (){
#filesystems=`df -P | grep ^/ |sed -e '/^none/d' -e '/^Filesystem/d' -e 's#^/#@,/#g' | awk '{ print $1","$5","$6 }'`
filesystems=$(df -P | grep ^/ |sed -e '/^none/d' -e '/^Filesystem/d' -e 's#^/#@,/#g' | awk '{ print $1","$5","$6 }')
#Define the name of the file we're going to use for a read-only check
touchfile=".`date +%N`.qd"
echo  "Partition        Use Mountpoint            Status       CAPACITY      INODES"
#      /dev/vda1     55% /                  [Writeable] [  > 90%  ]


#Loop for checking each file system for fullness and writeability
for fs in `echo $filesystems| grep @`
do
partition=`echo $fs | cut -d, -f2`
percentfull=`echo $fs | cut -d, -f3 | sed 's/%//'`
mountpoint=`echo $fs | cut -d, -f4`
#echo $partition $percentfull $mountpoint
inodefull=`df -P -i | grep $partition| grep ^/ |sed -e '/^none/d' -e '/^Filesystem/d' -e 's#^/#@,/#g' | awk '{ print $5 }'| cut -d% -f1`

touch $mountpoint/$touchfile >/dev/null 2>&1
if [ -f $mountpoint/$touchfile ]
        then
                writeable=" Writeable "
                rm -f $mountpoint/$touchfile
                fsw=$grn
        else
                writeable=" READ ONLY "
                fsw=$red
fi

if test ${percentfull} -le 89
        then
                capwarn="    OK    "
                capco=$grn
        else
                if test $percentfull -ge 99
                        then
                                capwarn=" CRITICAL "
                                capco=$red
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
        else
                if test $inodefull -ge 99
                        then
                                inodewarn=" CRITICAL "
                                inodeco=$red
                        else
                        if test $inodefull -ge 90
                                then
                                        inodewarn="   WARN   "
                                        inodeco=$yel
                                else true
                        fi
                fi
fi

printf "%-15s ${capco}%3s%%${NC} %-18s [${fsw}%-10s${NC}] [${capco}%10s${NC}] [${inodeco}%10s${NC}]\n" "${partition}" "${percentfull}" "${mountpoint}" "${writeable}" "${capwarn}" "${inodewarn}"

done
}
########### END File system checking




########## BEGIN Web Services checking
checkweb (){
# Find out what web server is in use
#port80=`lsof -P -i:80 | awk '{ print $1 }' | head -1`
#port8080=`lsof -P -i:8080 | awk '{ print $1 }' | head -1`
port80=`lsof -P -i:80 | awk '{ print $1 }' | sort | uniq -c | sort -n | tail -1 | awk '{ print $2 }'`
port8080=`lsof -P -i:8080 | awk '{ print $1 }' | sort | uniq -c | sort -n | tail -1 | awk '{ print $2 }'`
#echo $port80
#echo $port8080

#if 80 is dead, raise a red flag and stop checking
if [ -z ${port80} ]
        then
                status80="${red}WEB SERVER OFFLINE${NC}"
        else
#but if it's alive, check to see if it's nginx or apache
                if [[ ${port80} == httpd ]];
                        then
                                status80="${grn}Apache OK${NC}"
                else
                        if [[ ${port80} == nginx ]];
                                then
                                 status80="${grn}Nginx OK${NC}"
#if it's nginx, make sure apache is on 8080.
                                if [[ ${port8080} == httpd ]]
                                        then
                                                status8080="${grn}Apache OK${NC}"
                                        else
                                                status8080="${red}Apache OFFLINE${NC}"
                                fi
                        fi
                fi
fi
echo -e "Web Port 80:  "${status80}
if [[ ${port8080} == httpd ]]
        then
                echo -e "Web Port 8080:"${status8080}
fi
}

##### Function: Postfix queue check
ebpc=$(mailq | tail -1 | awk '{ print $5 }')
if [ -z $ebpc ]
        then
        cebpc="${grn}Empty${NC}"
        else
                if test ${ebpc} -le 1999
                        then
                                cebpc="${grn}${ebpc}${NC}"
                        else
                        cebpc="${red}${ebpc}${NC}"
                fi
fi
##### End Function: Postfix queue check

if [ "$(lsof -i:3306 | awk '{ print $1}' | tail -1)" == "mysqld" ]
        then
                cmysql="${grn}MySQL OK${NC}"
        else
                cmysql="${red}MySQL DOWN${NC}"

fi

if [ "$(lsof -i:110 | awk '{ print $1}' | tail -1)" == "dovecot" ]
        then
                cdovecot="${grn}Dovecot OK${NC}"
        else
                cdovecot="${red}Dovecot DOWN${NC}"

fi

if [ "$(lsof -i:25 | awk '{ print $1}' | tail -1)" == "smtpd" ]
        then
                cpostfix="${grn}Postfix OK${NC}"
        else
                cpostfix="${red}Postfix DOWN${NC}"

fi


echo "--------------------------------"
echo "Hostname      "`hostname`
echo "Uptime:       "${uptime}
checkweb
echo -e "MySQL:        "${cmysql}
echo -e "Postfix:      "${cpostfix}
echo -e "Dovecot:      "${cdovecot}

echo -e "Mail Queue:   "${cebpc}

#echo "Disk Status:  "${}
echo "--------------------------------"
#checkfs |sed -e 's#/dev/mapper/#/#' -e 's/VolGroup/VG/' -e 's/LogVol/LV/'
checkfs
