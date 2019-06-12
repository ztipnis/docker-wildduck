#!/bin/bash
 case $1 in
    start)
        echo "Starting RSpamd..."
        set -e
        (rspamd -f -i -u wildduck -g wildduck> /var/log/rspamd.log 2>/var/log/rspamd_error.log) &
        echo $! > /var/run/rspamd.pid
        ;;
     stop)  
       kill `cat /var/run/rspamd.pid` ;;
     *)  
       echo "usage: rspamd {start|stop}" ;;
 esac
 exit 0