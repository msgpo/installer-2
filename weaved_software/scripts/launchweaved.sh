#! /bin/bash

WEAVED_PORT=
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved/services
BIN_DIR=/usr/bin
PID_DIR=/var/run
BIN_PATH=$BIN_DIR/$DAEMON
PIDPATH=$PID_DIR/$WEAVED_PORT.pid
LOG_FILE=/dev/null
LOG_DIR=~/


if [ -z "$1" ]; then
	echo "You need one of the following arguments: start|stop|restart"
	exit
fi 
if [ "$(echo "$1" | tr '[A-Z]' '[a-z]' | tr -d ' ')" = "stop" ]; then 
	echo "Stopping $WEAVED_PORT"
	sudo kill "$(ps ax | grep $WEAVED_PORT | grep -v grep | awk '{print $1}')"
	sudo rm $PIDPATH
elif [ "$(echo "$1" | tr '[A-Z]' '[a-z]' | tr -d ' ')" = "start" ]; then
	if [ -z "$(ps ax | grep $WEAVED_PORT | grep -v grep)" ]; then
		echo "Starting $WEAVED_PORT"
		sudo $BIN_DIR/$DAEMON -f $WEAVED_DIR/$WEAVED_PORT.conf -d $PID_DIR/$WEAVED_PORT.pid > $LOG_DIR/$WEAVED_PORT.log
	else
		echo "$WEAVED_PORT is already started"
	fi
elif [ "$(echo "$1" | tr '[A-Z]' '[a-z]' | tr -d ' ')" = "restart" ]; then
	echo "Stopping $WEAVED_PORT"
	sudo kill "$(ps ax | grep $WEAVED_PORT | grep -v grep | awk '{print $1}')"
	sudo rm $PIDPATH
	echo "Starting $WEAVED_PORT"
	sudo $BIN_DIR/$DAEMON -f $WEAVED_DIR/$WEAVED_PORT.conf -d $PID_DIR/$WEAVED_PORT.pid > $LOG_DIR/$WEAVED_PORT.log

else
	echo "This option is not supported"
fi
