#!/bin/bash

# Author	:	Abhishek S. Okheda <abhi.emailto@gmail.com>
# Date		:	2014-05-14
# Purpose	:	Change IP in BIND zone file

new_ip="$1"

named_dir="/var/named"
zone="np-test.com"
zone_file="$named_dir/$zone.db"
server_host="server"
server_fqdn="$server_host.$zone."
logfile="/var/log/dynamicdns.log"


get_current_serial()
{
	cat $zone_file | grep '; Serial' | awk '{print $1}'
}

get_current_ip()
{
	cat $zone_file | grep "^$server_fqdn" | awk '{print $NF}'
}

get_new_serial()
{
	old_serial=`get_current_serial`
	serial_date=`echo "$old_serial" | cut -c1-8`
	today_date=`date +"%Y%m%d"`
	new_serial=""

	if [ $serial_date -lt $today_date ]
	then
		new_serial=$today_date"01"
	else
		today_serial=`echo $old_serial | cut -c9-`
		#log_line "DEBUG!!! current_serialno=$today_serial"
		today_serial=`expr $today_serial + 1`
		new_serial="$today_date$today_serial"
	fi
	#log_line "DEBUG!!! serial_date=$serial_date,today_date=$today_date,old_serial=$old_serial,new_serial=$new_serial"
	echo "$new_serial"
	return "$new_serial"
}

change_server_ip()
{
	new_ip="$1"
	serial=`get_new_serial`
	mv -vf $zone_file{,.old}
	cat $zone_file.old | sed "s/^$server_fqdn.*$/$server_fqdn\tIN\tA\t$new_ip/g; s/.*; Serial.*/\t\t\t$serial\t; Serial/g" > $zone_file
	#chown root:named $zone_file

	rndc reload $zone
	return $?
}

check_ip()
{
	ip="$1"
	#valid=`echo "$ip" | tr '.' '~' | sed -n -E /^\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-5][0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-5][0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-5][0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-5][0-5]\)$/p`
	#return 0

	valid=`echo "$ip" | tr '.' '~' | sed -n -E /^\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\)~\([1-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\)$/p`
	if [ -z "$valid" ]
	then
		return 1
	fi
	return 0
}

log_line(){
	line="$1"
	echo -e `date +"%Y-%m-%d %H:%M:%S"`"\t\t$line" >> $logfile
}

main()
{
	check_ip "$new_ip"
	if [ $? -ne 0 ]
	then
		log_line "ERROR!!! Invalid_IP = '$new_ip'"
		exit 2
	fi
	old_ip=`get_current_ip`
	if [ "$new_ip" != "$old_ip" ]
	then
		change_server_ip $new_ip
		STATUS=$?
		if [ $STATUS -eq 0 ]
		then
			log_line "CHANGED!!! $server_fqdn = $old_ip >> $new_ip"
		else
			log_line "FAILED!!! $server_fqdn = $old_ip >> $new_ip"
			exit $STATUS 
		fi
	else
		echo "IP Same as previous. NOT editing DNS!!!"
		exit 1
	fi
}

main
