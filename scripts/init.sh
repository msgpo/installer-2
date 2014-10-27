#! /bin/sh
### BEGIN INIT INFO
# Provides:          weavedConnectd
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: weavedConnectd remote access proxy initscript
# Description:       for more info go to http://weaved.com
### END INIT INFO

WEAVED_PORT=WebIOPi8000
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
BIN_PATH=$BIN_DIR/$DAEMON
PIDPATH=$PID_DIR/$WEAVED_PORT.pid
LOG_FILE=/dev/null

#----------------------------------------
# End configuration                     -
# Do not edit below this line           -
#----------------------------------------

#
# PATH should only include /usr/* if it runs after the mountnfs.sh script
#PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Weaved Connectd Daemon"
SCRIPTNAME=/etc/init.d/$WEAVED_PORT

# Exit if the package is not installed
if [ ! -x "$BIN_PATH" ] ; then
    echo "cannot find $BIN_PATH"
    exit 0
fi

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
RETVAL=2
# Return
#   0 if daemon has been started
#   1 if daemon was already running
#   2 if daemon could not be started
if [ -f ${PIDPATH} ] ; then
    echo -n "already running "
    RETVAL=1
else
    $BIN_PATH -f $WEAVED_DIR/services/$WEAVED_PORT.conf -d $PIDPATH > $LOG_FILE
    sleep 1
if [ -f ${PIDPATH} ] ; then
    RETVAL=0
    echo -n " [OK]"
else
    echo -n " [FAIL]"
fi
fi

#start-stop-daemon --start --quiet --pidfile $PIDPATH --exec $DAEMON --test > /dev/null \
#	|| return 1
#start-stop-daemon --start --quiet --pidfile $PIDPATH --exec $DAEMON -- \
#	$DAEMON_ARGS \
#	|| return 2
# Add code here, if necessary, that waits for the process to be ready
# to handle requests from services started subsequently which depend
# on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
# Return
#   0 if daemon has been stopped
#   1 if daemon was already stopped
#   2 if daemon could not be stopped
#   other if a failure occurred
start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDPATH --name $WEAVED_PORT
RETVAL="$?"

if [ 1 -eq $RETVAL ] ; then
    echo -n " Not Running [FAIL]"
fi

if [ 0 -eq $RETVAL ] ; then
    echo -n " [OK]"
fi

if [ 2 -eq $RETVAL ] ; then
    echo -n " [FAIL]"
    return 2
fi

#killproc
[ "$RETVAL" = 2 ] && return 2
# Wait for children to finish too if this is a daemon that forks
# and if the daemon is only ever run from this initscript.
# If the above conditions are not satisfied then add some other code
# that waits for the process to drop all resources that could be
# needed by services started subsequently.  A last resort is to
# sleep for some time.
#start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
[ "$?" = 2 ] && return 2
# Many daemons don't delete their pidfiles when they exit.
rm -f $PIDPATH
return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
#
# If the daemon can reload its configuration without
# restarting (for example, when it is sent a SIGHUP),
# then implement that here.
#
start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDPATH --name $WEAVED_PORT
return 0
}

case "$1" in
start)
[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$WEAVED_PORT"
do_start
case "$?" in
0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
esac
;;
stop)
[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$WEAVED_PORT"
do_stop
case "$?" in
0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
esac
;;

restart|force-reload)
#
# If the "reload" option is implemented then remove the
# 'force-reload' alias
#
log_daemon_msg "Restarting $DESC" "$WEAVED_PORT"
do_stop
case "$?" in
0|1)
do_start
case "$?" in
0) log_end_msg 0 ;;
1) log_end_msg 1 ;; # Old process is still running
*) log_end_msg 1 ;; # Failed to start
esac
;;
*)
# Failed to stop
log_end_msg 1
;;
esac
;;
*)
#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
exit 3
;;
esac

:
