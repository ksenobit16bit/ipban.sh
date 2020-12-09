#!/bin/bash
export LC_ALL="en_US.UTF-8";
export PATH="/sbin:/usr/sbin:/bin/:/usr/bin"

LOG_PATH=/var/log/nginx/*access.log
IGNORE_LIST=/etc/ipban.sh/ignore_ip.list
state_file=/etc/ipban.sh/state.log
diff_date=86400 #set unban time
time=$1
limit=$2
dry=$3
###########################################
unban(){
	IFS=$'\n'
	cur_date=`date '+%s'`
	sub=$((${cur_date}-${diff_date}))
	iptables-save | grep added |while read -r line
		do
		 save_date=`echo $line | sed 's/^.*"added=\([^"]*\).*$/\1/'`
		 save_tmstamp=`date --date="$save_date" '+%s'`
		if [ ${save_tmstamp} -le ${sub} ]
			then
 	   cmd=`echo ${line} | sed 's/^-A\(.*\)$/iptables -D\1/'`
 	   eval ${cmd}
		fi
			done
}

banip(){
	if [[ $(iptables-save | grep -c $ip) -eq 1 ]]
		then echo "alredy banned" >> $state_file
	else
		iptables -I INPUT -s $ip -m comment --comment "added=`date`" -j DROP
		echo "ip '$ip' banned at `date` | time was $time | limit was $limit" >> $state_file
	fi
}

startup_check(){
	if ! [ -d /etc/ipban.sh/ ] 
	then
		echo -e "creating dir /etc/ipban.sh/... \nplease, create /etc/ipban.sh/ignore_ip.list and add ip's to ignore in ignore_ip.list"
		mkdir /etc/ipban.sh/
	fi

	if ! [ -f /etc/ipban.sh/ignore_ip.list ]
	then 
		echo "create file /etc/ipban.sh/ignore_ip.list and add ip's to ignore"
		exit 1
	fi
}
###########################################
#startup checks, time and dirs
startup_check
#help section
	if [[ $1 -eq 0 ]] || [[ $2 -eq 0 ]] || [ $# -eq 0 ]
	then
  		echo -e "set search time in minutes and set limits. \n Usage: $0 <minutes> <limit> <dry_run=1/0>"
   		exit 1
	fi

	if [[ $3 -eq 1 ]]
	then
		reqests=$(awk -vDate=`date -d'now-'$time' minute' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date +[%d/%b/%Y:%H:%M:%S` '$4 > Date && $4 < Date2 {print $1}' $LOG_PATH | sort | uniq -c | grep -v -f $IGNORE_LIST | sort -nr | head -n 1)
		echo "you start in dry_run mode:"
		echo "reqests = $reqests"
		echo "limit = $limit"
		exit 0
	fi


#let's find bad ip's!
reqests=$(awk -vDate=`date -d'now-'$time' minute' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date +[%d/%b/%Y:%H:%M:%S` '$4 > Date && $4 < Date2 {print $1}' $LOG_PATH | sort | uniq -c | grep -v -f $IGNORE_LIST | sort -nr | head -n 1)
echo $reqests > /etc/ipban.sh/reqests-count.log
count=$(cat /etc/ipban.sh/reqests-count.log | awk '{print $1}')
	if [[ $count -gt $limit ]] 
	then
		ip=$(cat /etc/ipban.sh/reqests-count.log | awk '{print $2}')
		banip
		unban
	else
		echo -e "no ip banned at `date` | time was $time | limit was $limit" >> $state_file
		unban
	fi

