#!/bin/bash
 case $1 in
    start)
		echo "Starting Haraka..."
		set -e
		(haraka -c /opt/haraka > /var/log/haraka.log 2>/var/log/haraka_error.log) &
		echo $! > /var/run/haraka.pid
	    ;;
     stop)  
       kill `cat /var/run/haraka.pid` ;;
     *)  
       echo "usage: haraka {start|stop}" ;;
 esac
 exit 0