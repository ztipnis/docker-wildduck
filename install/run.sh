#!/bin/bash
for x in ("/bin" "/sbin" "/usr/sbin" "/usr/bin" "/opt/.npm-global/bin"); do
  case ":$PATH:" in
    *":$x:"*) :;; # already there
    *) PATH="$PATH:$x";;
  esac
done
CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
if [ ! -e $CONTAINER_ALREADY_STARTED ]; then
	touch $CONTAINER_ALREADY_STARTED
    echo "-- First container startup --"
    source ./config.sh
fi
cd /src/
apk --update --no-cache upgrade &

source ./deploy.sh &
monit -I $@