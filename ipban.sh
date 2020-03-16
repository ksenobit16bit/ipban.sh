#!/bin/bash
export LC_ALL="en_US.UTF-8";
LOG_PATH=/var/log/nginx/*access.log
IGNORE_LIST=/etc/ipbans/ignore_ip.list
state_file=/etc/ipbans/state.log
diff_date=86400 #set unban time
time=$1
limit=$2 #set reqests limit
###########################################
unban(){
		IFS=$'\n'
	export PATH="/sbin:/usr/sbin:/bin/:/usr/bin"
	#diff_date=86400 #set unban time

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

checkip(){
	if [[ $(iptables-save | grep -c $ip) -eq 1 ]]
		then echo "alredy banned" >> $state_file
	else
		iptables -I INPUT -s $ip -m comment --comment "added=`date`" -j DROP
		echo "ip '$ip' banned at `date`" >> $state_file
		unban
	fi
}

check_dir(){
	if ! [ -d /etc/ipbans/ ] 
	then
		echo "please, create dir /etc/ipbans/ "
		exit 1
	fi

	if ! [ -f /etc/ipbans/ignore_ip.list ]
	then 
		echo "please, create file /etc/ipbans/ignore_ip.list and add ip's to ignore!"
		exit 1
	fi
}


###########################################
#startup checks, time and dirs
	if [[ $1 -eq 0 ]] || [[ $2 -eq 0 ]] || [ $# -eq 0 ]
then
   echo -e "set search time in minutes and set limits. \n Usage: $0 <minutes> <limit>"
   exit 1
fi


check_dir

#let's find bad ip's!
reqests=$(awk -vDate=`date -d'now-'$time' minute' +[%d/%b/%Y:%H:%M:%S` -vDate2=`date +[%d/%b/%Y:%H:%M:%S` '$4 > Date && $4 < Date2 {print $1}' $LOG_PATH | sort | uniq -c | grep -v -f $IGNORE_LIST | sort -nr | head -n 1)
echo $reqests > /etc/ipbans/reqests-count.log
count=$(cat /etc/ipbans/reqests-count.log | awk '{print $1}')
	if [[ $count -gt $limit ]] 
	then
		#echo "1"
		ip=$(cat /etc/ipbans/reqests-count.log | awk '{print $2}')
		checkip
	else
		#echo "0"
		echo -e "no ip banned at `date` | time was $time | limit was $limit" >> $state_file
		unban
	fi