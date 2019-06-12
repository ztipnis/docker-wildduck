 case $1 in
    start)
    	set -e
      cd /opt/zone-mta
		  (node index.js --config="/etc/zone-mta/zonemta.toml" > /var/log/zonemta.log 2>/var/log/zonemta_error.log )&
      echo $! > /var/run/zonemta.pid; 
       ;;
     stop)  
       kill `cat /var/run/zonemta.pid` ;;
     *)  
       echo "usage: zonemta.sh {start|stop}" ;;
 esac
 exit 0