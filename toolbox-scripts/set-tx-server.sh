#!/bin/bash
#
# set which terminal server to use
#
# 2025-11-16 Helma van der Linden
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in <root>/scripts
ROOT_DIR="$( dirname "$ME_DIR" )"

# date (now)
DT=$(date +"%Y-%m-%d")

PIDFILE="/tmp/mitmdump.pid"

stop_if_running () {
    if [[ ! -f "$PIDFILE" ]]; then
        return 0
    fi

    pid=$(cat "$PIDFILE")

    # Check if it's running (no ps needed)
    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing process $pid"
        kill "$pid"
    else
        echo "PID $pid is not running"
    fi

    rm -f "$PIDFILE"
}

if [[ $USE_NTS == "y" || $USE_NTS == "Y" ]]; then
    stop_if_running $PIDFILE

	echo "Starting proxy for the Nationale Terminologieserver"
	# export NTS_USER
	# export NTS_PASS
	mitmdump -s /usr/share/ntsproxy/NTS-proxy.py > /dev/null &
	echo $! > $PIDFILE
	sleep 3s
	curl_line="--proxy http://localhost:8080 http://terminologieserver.nl/fhir/metadata"
else
	curl_line="https://tx.fhir.org"
fi

echo Checking internet connection...
curl -sSf $curl_line > /dev/null
if [ $? -eq 0 ]; then
    if [[ $USE_NTS == "y" || $USE_NTS == "Y" ]]; then
		echo "Using the Nationale Terminologieserver"
		txoption="-proxy localhost:8080 -tx http://terminologieserver.nl/fhir"
	else
		echo "Using the default terminology server (tx.fhir.org)"
		txoption=""
	fi
else
	echo "Offline"
	txoption="-tx n/a"
fi

echo $txoption > $HOME/.txoption
