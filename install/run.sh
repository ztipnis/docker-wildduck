#!/bin/bash
ifconfig
apk update
apk upgrade
echo "Fetching Virus Definitions..."
(
	set +e
	clamd&
	sleep 5
	freshclam
)
echo "Starting Haraka..."
(
	set -e
	haraka -c /opt/haraka &
)
sleep 10
echo "Starting ZoneMTA.."
(
	set -e
	cd /opt/zone-mta
	node index.js --config="/etc/zone-mta/zonemta.toml"
)
sleep 10
echo "Starting WildDuck IMAP.."
(
	set -e
	cd /opt/wildduck
	node server.js --config=/etc/wildduck/wildduck.toml
)
source ./deploy.sh