#!/bin/bash
declare -a path_fix=("/bin" "/sbin" "/usr/sbin" "/usr/bin" "/opt/.npm-global/bin")
for x in "${path_fix[@]}"; do
  case ":$PATH:" in
    *":$x:"*) :;; # already there
    *) export PATH="$PATH:$x";;
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