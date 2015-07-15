<?php
# Author	:   Abhishek S. Okheda <abhi.emailto@gmail.com>
# Date		:   2014-05-14 
# Purpose	:   Reciever of DNS Change request by client


	if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
      		$remote_ip=$_SERVER['HTTP_X_FORWARDED_FOR'];
	} else {
      		$remote_ip=$_SERVER['REMOTE_ADDR'];
    	}
	#echo $remote_ip;
	#$ret=`./update_ip.sh $remote_ip >/dev/null 2>&1; echo $?`;
	$ret=`./update_ip.sh $remote_ip > /tmp/ddns 2>&1; echo $?`;
	echo $ret;
?>
