 case $1 in
    start)
      set -e
  		cd /opt/wildduck
  		(node server.js --config=/etc/wildduck/wildduck.toml > /var/log/wildduck.log 2>/var/log/wildduck_error.log)&
      echo $! > /var/run/wildduck.pid
       ;;
     stop)  
       kill `cat /var/run/wildduck.pid` ;;
     *)  
       echo "usage: wildduck.sh {start|stop}" ;;
 esac
 exit 0