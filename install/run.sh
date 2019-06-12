#!/bin/bash

CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
if [ ! -e $CONTAINER_ALREADY_STARTED ]; then
	touch $CONTAINER_ALREADY_STARTED
    echo "-- First container startup --"
    set +e
	addgroup -S wildduck
	adduser -S -H -D wildduck -G wildduck
	set -e
	(
		export NODE_PATH=`command -v node`
		export SRS_SECRET=`pwgen 12 -1`
		apk --update add --no-cache gettext
		echo "$(export DKIM_SECRET=`pwgen 12 -1` && envsubst < /src/config/dkim.toml)" > "/etc/wildduck/dkim.toml"
		apk del gettext
		export ZONEMTA_SECRET=`pwgen 12 -1`
		echo "[\"modules/zonemta-loop-breaker\"]
		enabled=\"sender\"
		secret=\"$ZONEMTA_SECRET\"
		algo=\"md5\"" > /etc/zone-mta/plugins/loop-breaker.toml

		echo "[wildduck]
		enabled=[\"receiver\", \"sender\"]
		# which interfaces this plugin applies to
		interfaces=[\"feeder\"]
		# optional hostname to be used in headers
		# defaults to os.hostname()
		hostname=\"$HOST\"
		# How long to keep auth records in log
		authlogExpireDays=30
		# SRS settings for forwarded emails
		[wildduck.srs]
		    # Handle rewriting of forwarded emails
		    enabled=true
		    # SRS secret value. Must be the same as in the MX side
		    secret=\"$SRS_SECRET\"
		    # SRS domain, must resolve back to MX
		    rewriteDomain=\"$HOST\"
		[wildduck.dkim]
		# share config with WildDuck installation
		# @include \"/etc/wildduck/dkim.toml\"
		" > /etc/zone-mta/plugins/wildduck.toml

		cd /opt/zone-mta/keys
		# Many registrar limits dns TXT fields to 255 char. 1024bit is almost too long:-\
		openssl genrsa -out "$HOST-dkim.pem" 1024
		chmod 400 "$HOST-dkim.pem"
		openssl rsa -in "$HOST-dkim.pem" -out "$HOST-dkim.cert" -pubout
	)
fi
cd /src/
apk --update --no-cache upgrade &
if [[ "$MMONIT_ENABLED" = "true" ]]; then
	echo "set mmonit http://$MMONIT_USER:$MMONIT_PASS@$MMONIT_HOST:$MMONIT_PORT/collector" > /etc/monitrc
else
	echo "" > /etc/monitrc
fi
echo '
set daemon 5
set httpd port 2812
  allow 0.0.0.0/0.0.0.0
check process rspamd with pidfile /var/run/rspamd.pid
   start = "/bin/bash -c '"'"'/src/rspamd.sh start'"'"'"
   stop = "/bin/bash -c '"""'/src/rspamd.sh stop'"""'"
   if 3 restarts within 5 cycles then alert
check process haraka with pidfile /var/run/haraka.pid
   start = "/bin/bash -c '"'"'/src/haraka.sh start'"'"'"
   stop = "/bin/bash -c '"""'/src/haraka.sh stop'"""'"
   if 3 restarts within 5 cycles then alert
check process zonemta with pidfile /var/run/zonemta.pid
   start = "/bin/bash -c '"'"'/src/zonemta.sh start'"'"'"
   stop = "/bin/bash -c '"'"'/src/zonemta.sh stop'"'"'"
   if 3 restarts within 5 cycles then alert
check process wildduck with pidfile /var/run/wildduck.pid
   start = "/bin/bash -c '"'"'/src/wildduck.sh start'"'"'"
   stop = "/bin/bash -c '"'"'/src/wildduck.sh stop'"'"'"
   if 3 restarts within 5 cycles then alert
' >> /etc/monitrc
source ./deploy.sh &
monit -I