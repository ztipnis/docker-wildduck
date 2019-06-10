#!/bin/bash
echo "Starting Haraka..."
(
	haraka -c /opt/haraka &
)
sleep 10
echo "Starting ZoneMTA.."
(
	cd /opt/zone-mta
	npm start
)
sleep 10
echo "Starting WildDuck IMAP.."
(
	cd /opt/wildduck
	node server.js --config=/etc/wildduck/default.toml
)
source ./deploy.sh