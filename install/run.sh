#!/bin/bash
apk update
apk upgrade
(
	echo "Fetching Virus Definitions..."
	set +e
	mkdir -p /run/clamav
	chmod 755 /run/clamav
	freshclam
	clamd
)&(
	sleep 10
	echo "Starting Haraka..."
	set -e
	haraka -c /opt/haraka 
)&(
	sleep 20
	echo "Starting ZoneMTA.."
	set -e
	cd /opt/zone-mta
	node index.js --config="/etc/zone-mta/zonemta.toml"
)&(
	sleep 30
	echo "Starting WildDuck IMAP.."
	set -e
	cd /opt/wildduck
	node server.js --config=/etc/wildduck/wildduck.toml &
)& source ./deploy.sh