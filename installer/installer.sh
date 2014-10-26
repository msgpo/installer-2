#!/bin/bash

#  Weaved_WebIOPi.sh
#  
#
#  Weaved, Inc. Copyright 2014. All rights reserved.
#

##### Settings #####
WEAVED_PORT=WebIOPi8000
PLATFORM=linux
OS=raspbian
SYSLOG=/var/log/syslog
DAEMON=weavedConnectd
FILE=/etc/apt/sources.list
KEY=/tmp/weaved/key
ROOT_UID=0
CMD_SUCCEED=0
ERR_USER=1
ERR_CD=2
ERR_FILE=3
ERR_UPDATE_FILE=4
ERR_UPDATE_KEY=5
ERR_UPDATE=6
ERR_INSTALL=7
ERR_CONFIG=8
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
filename=$(basename $0)
loginURL=https://api.weaved.com/api/user/login
unregdevicelistURL=https://api.weaved.com/api/device/list/unregistered
regdeviceURL=https://api.weaved.com/api/device/register
##### End Settings #####

##### Check for Bash #####
bashCheck()
{
    if [ "$BASH_VERSION" = '' ]; then
        clear
        printf "You executed this script with dash vs bash! \n\n"
        printf "Unfortunately, not all shells are the same. \n\n"
        printf "Please execute \"chmod +x $filename\" and then \n"
        printf "execute \"./$filename\".  \n\n"
        printf "Thank you! \n"
        exit
    else
        #clear
        echo "Now launching the Weaved connectd daemon installer..."
    fi
    #clear
}
##### End Bash Check #####

######### Ask Function #########
ask()
{
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
            fi
    # Ask the question
    read -p "$1 [$prompt] " REPLY
    # Default?
    if [ -z "$REPLY" ]; then
        REPLY=$default
    fi
    # Check if the reply is valid
    case "$REPLY" in
    Y*|y*) return 0 ;;
    N*|n*) return 1 ;;
    esac
    done
}
######### End Ask Function #########

#########  Non Numeric Values #########
numericCheck()
{
    test -z "$input" -o -n "`echo $input | tr -d '[0-9]'`" && echo NaN
}
#########  End Non Numeric Values #########

#########  Check prior installs #########
checkForPriorInstalls()
{
    if [ -e "/usr/bin/$DAEMON" ]; then
        clear
        printf "It looks as if there's a previous version of WeaveConnectd service installed. \n\n"
        if ask "Would you like to uninstall the prior installation before proceeding? "; then
            printf "\nUninstalling prior installation of Weaved's Connectd service... \n"
            if [ -e $INIT_DIR/$WEAVED_PORT ]; then
                sudo $INIT_DIR/$WEAVED_PORT stop
            fi

            if [ -d $WEAVED_DIR ]; then
                sudo rm -rf $WEAVED_DIR
                printf "$WEAVED_DIR now deleted \n"
            fi

            if [ -e $BIN_DIR/$DAEMON ]; then
                sudo rm -r $BIN_DIR/$DAEMON
                printf "$BIN_DIR/$DAEMON now deleted \n"
            fi

            if [ -e $BIN_DIR/$NOTIFIER ]; then
                sudo rm -r $BIN_DIR/$NOTIFIER
                printf "$BIN_DIR/$NOTIFIER now deleted \n"
            fi

            if [ -e $INIT_DIR/$WEAVED_PORT ]; then
                sudo rm $INIT_DIR/$WEAVED_PORT
                printf "$INIT_DIR/$WEAVED_PORT now deleted \n"
            fi

            if [ -e $INIT_DIR/$WEAVED_PORT ]; then
                sudo rm $PID_DIR/$WEAVED_PORT.pid
                printf "$PID_DIR/$WEAVED_PORT.pid now deleted \n"
            fi

            start="2 3 4 5"
            for i in $start; do
              sudo rm -f /etc/rc$i.d/S20$WEAVED_PORT
            done
            stop="0 1 6"
            for i in $stop; do
                if [ -e /etc/rc$i.d/K01$WEAVED_PORT ]; then
                    sudo rm -f /etc/rc$i.d/K01$WEAVED_PORT
                fi
            done
            if [ -e $BIN_DIR/send_notification.sh ]; then
                sudo rm $BIN_DIR/send_notification.sh
                printf "$BIN_DIR/send_notification.sh now deleted \n\n"
                printf "Prior installation now removed. Now proceeding with new installation... \n"
            fi
        else
            printf "\nYou've chosen not to remove your old installation files.  \n"
            printf "The following files will be either created or overwritten: \n\n"
            printf "$BIN_DIR/$DAEMON \n"
            printf "$WEAVED_DIR/services/$WEAVED_PORT.conf \n"
            printf "$INIT_DIR/$WEAVED_PORT \n"
            printf "$BIN_DIR/$NOTIFIER \n"
            printf "$PID_DIR/$WEAVED_PORT.pid \n\n"
        fi
    fi
}
#########  Check prior installs #########

######### Begin Portal Login #########
userLogin () #Portal login function
{
    printf "Please enter your Weaved Portal Username (email address): \n"
    read username
    printf "\nNow, please enter your password: \n"
    read  -s password
    resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" "$loginURL/$username/$password")
    token=$(echo "$resp" | awk -F ":" '{print $3}' | awk -F "," '{print $1}' | sed -e 's/^"//'  -e 's/"$//')
    loginFailed=$(echo "$resp" | grep "login failed" | sed 's/"//g')
    login404=$(echo "$resp" | grep 404 | sed 's/"//g')
}
######### End Portal Login #########

######### Test Login #########
testLogin()
{
    while [[ "$loginFailed" != "" || "$login404" != "" ]]; do
        clear
        printf "You have entered either an incorrect username or password. Please try again. \n\n"
        userLogin
    done
}
######### End Test Login #########

######### Install Enablement #########
installEnablement()
{
    if [ ! -d "WEAVED_DIR" ]; then
       sudo mkdir -p $WEAVED_DIR/services
    fi

cat > $WEAVED_PORT.conf <<'EOF'
#begin <do not modify section> of weaved provisioning file.
289F90BF-452B-E7EE-D880-896890200460
1
vmlv6KuwblUU1fBwJJWEy3Cbdos=
-----BEGIN CONFIG-----
US/1i4lbtsBjM4Zxxwv4XOjLxuDkN0nrMZDXtBZ+F8PeR04Eeq5364VtrmyX1TT5
vwbZ3sgzzkcE1UowMQsBsHoMd/fEWkXmC+2+tjMfTqGchxJIMfdK8YwDU5oZG5O+
vM0MLHalJFmFrF6GKUjhZuVjb0wNFWcmd29uMqUlW2cB64r8U1ts1aGRSUke3XgR
ZIYHaxM8cRJ0tCPN4jorruxFoDizEN1TlopOE/pggglIAeffjmVgvmK80bdK210u
vyLqktyw0chI4TxNeOYW/jrRPVlBwCOu+Yx9RDBUDTBJ1OuucFnCr6uiQa1mJ+rK
eSgNy9HFrQmITQL88eQu9Xq6JIrf1uAkqordcsSzYVVWIib8dhDSVHmY0sBP2fIO
8Ft9a6eVeV8HDa+5UuvzRbKWi93sdpZpsbr6Xc7btb0UYErCozrtj0tR73quoBt+
LSHl17JRBmTAAYKcuqIIaN7TKF3BzfRWUe+EUf/e2rS5ApAxhHvUsedVY5Ua6O3v
FLCIzqNIn757tkGuLJAVpqyYYNGf
-----END CONFIG-----
#end <do not modify section> custom configurations after this line>
#note <you must remove all the lines below to copy this enablement to another device>
EOF

sudo mv $WEAVED_PORT.conf $WEAVED_DIR/services/$WEAVED_PORT.conf
}
######### End Install Enablement #########

######### Install Notifier #########
installNotifier()
{
cat > notify.sh <<'EOF'
#!/bin/sh
#
# Copyright (C) 2014 Weaved Inc
#
# This is a simple notifcation script that can send events to the weaved notification server
#
# Usage:  old_notify.sh <type> <UID> <secret> <message string> <status string>
#
# type 0 =auth only
# type 1 =arc4 encrypted
# type 3 =aes128 encrypted (TBD)
#
# Example:
#           notify.sh 0 00:00:48:02:2A:A0:32:2D BA4F204876384F921F714DD177CE12D360593CCD "this is a msg" "this is a status"
#
#
# Config curl path
CURL="curl"

#Default values
TMP="/tmp"
# Don't veryify SSL (-k) Silent (-s)
CURL_OPS=" -k -s"
DEBUG=1
#SRC=$1
#DST=$2
OUTPUT="$TMP/notification.txt"
WRITE_DB_STRING="/bin/ffdb -s -d /data/cfg/config.lua -t /data/cfg/ffdb.tmp"

NOTIFICATION_SERVER="notification.yoics.net"
#NOTIFICATION_SERVER="home.mycal.net"
NOTIFICATION_VERSION="/v2"
NOTIFICATION_SEND_URI_AUTH="${NOTIFICATION_VERSION}/send_notification_auth.php?"
NOTIFICATION_SEND_URI="${NOTIFICATION_VERSION}/send_notification.php?"
# Build API URLS GET API's
API_GET_TRANSACTION_CODE="http://$NOTIFICATION_SERVER${NOTIFICATION_VERSION}/request_code.php?uid="
API_SEND_EVENT="http://${NOTIFICATION_SERVER}${NOTIFICATION_SEND_URI}"
API_SEND_EVENT_AUTH="http://${NOTIFICATION_SERVER}${NOTIFICATION_SEND_URI_AUTH}"
#
# Default templates
#
# Load values from FFDB
#
#WEAVED_USER=$(/bin/ffdb -q -d /data/cfg/config.lua STORAGE_CFG0)

#
# Helper Functions
#
#produces a unix timestamp (seconds based) to the output
utime()
{ 
    echo $(date +%s)
}

#
# Produce a sortable timestamp that is year/month/day/timeofday
#
timestamp()
{
    echo $(date +%Y%m%d%H%M%S)
}

# produces a random number ($1 digits) to the output (supports upto 50 digits for now)
dev_random()
{
    local count=$1
    
    #defualt is 10 digits if none specified
    count=${1:-10};

    #1 to 50 digits supported
    if [ "$count" -lt 1 ] || [ "$count" -ge 50 ]; then
        count=10;
    fi

    # uses /dev/urandom
    ret=$(cat /dev/urandom | tr -cd '0-9' | dd bs=1 count=$count 2>/dev/null)
    echo $ret
}

# XML parse,: get the value from key $2 in buffer $1, this is simple no nesting allowed 
#
xmlval()
{
    temp=`echo $1 | awk '!/<.*>/' RS="<"$2">|</"$2">"`
    echo ${temp##*|}
}

#
# get value frome key $2 in buffer $1 (probably better but more work)
#
#jsonval() 
#{
#    temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
#    echo ${temp##*|}
#}

#
# JSON parse (very simplistic):  get value frome key $2 in buffer $1,  values or keys must not have the characters {}", and the key must not have : in them
#
jsonval()
{
    temp=`echo $1 | sed -e 's/[{}"]//g' -e 's/,/\n/g' | grep -w $2 | cut -d":" -f2-`
    echo ${temp##*|}
}


#
# urlencode $1
#
urlencode()
{
STR=$1

#[ ${STR}x == "x" ] && { STR="$(cat -)"; }
#[ "${STR}x" == "x" ] && { echo "i"; }

echo "${STR}" | sed -e 's| |%20|g' \
-e 's|!|%21|g' \
-e 's|#|%23|g' \
-e 's|\$|%24|g' \
-e 's|%|%25|g' \
-e 's|&|%26|g' \
-e "s|'|%27|g" \
-e 's|(|%28|g' \
-e 's|)|%29|g' \
-e 's|*|%2A|g' \
-e 's|+|%2B|g' \
-e 's|,|%2C|g' \
-e 's|/|%2F|g' \
-e 's|:|%3A|g' \
-e 's|;|%3B|g' \
-e 's|=|%3D|g' \
-e 's|?|%3F|g' \
-e 's|@|%40|g' \
-e 's|\[|%5B|g' \
-e 's|]|%5D|g'
}

#
#
#
return_code()
{
    case $resp in
        "200")
            #Good Reponse
            echo "$resp OK"
            ;;
        "400" | "401" | "403" | "404" | "405")
            #Bad input parameter. Error message should indicate which one and why.
            ret=$(jsonval "$(cat $OUTPUT)" "errorCode")
            ret2=$(jsonval "$(cat $OUTPUT)" "message" )
            echo "$resp $ret : $ret2"
            ;;
        "429")
            #Your app is making too many requests and is being rate limited. 429s can trigger on a per-app or per-user basis.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
        "503")
            #If the response includes the Retry-After header, this means your OAuth 1.0 app is being rate limited. Otherwise, this indicates a transient server error, and your app should retry its request.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
        "507")
            #User is over Dropbox storage quota.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
    esac
}


#
# hash_hmac "sha1" "value" "key"
# raw output by adding the "-binary" flag
# other algos also work: hash_hmac "md5"  "value" "key"
#
#echo -n '952dd27cd1c9369ea091e67e7c3a766700:00:48:02:2A:A0:32:2D00:13:00:10:00:07:00:02:04:21:00:00status20140711190851test' | openssl dgst -binary -sha1 -hmac 'BA4F204876384F921F714DD177CE12D360593CCE' | openssl base64

hash_hmac() 
{
    digest="$1"
    data="$2"
    key="$3"
    shift 3
    echo -n "$data" | openssl dgst -binary "-$digest" -hmac "$key" "$@" | openssl base64
}

hash_hmac_key()
{
    digest="$1"
    data="$2"
    key="$3"
    shift 3
    echo -n "$data" | openssl dgst "-$digest" -hmac "$key" "$@" | sed 's/^.* //'
}

#
# Encrypt RC4 with key, base 64 the output
#
encrypt_rc4()
{
    tkey="$1"
    data="$2"
   
#    echo "encrpte rc4-->echo -n $data | openssl rc4 -K $tkey -nosalt -e -nopad -p | openssl base64"

    echo -n "$data" | openssl rc4 -K $tkey -nosalt -e -nopad -a -A
}

logger "[Weaved Notification Called $1 $2 $3 $4 $5 ]"

type=$1
uid=$2
secret=$3
msg=$(echo "$4" | openssl base64)
status=$(echo "$5" | openssl base64)

#could verify inputs here

#
# always get transaction code
#
URL="$API_GET_TRANSACTION_CODE$2"
resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" "$URL")

if [ "$resp" -eq 200 ]; then
    # echo URL "return USERID"
    ret=$(xmlval "$(cat $OUTPUT)" "status")
    # ret has status
    if [ "$ret"="ok" ]; then
        # extract transaction code and fall through
        transaction_code=$(xmlval "$(cat $OUTPUT)" "code")
    else
        echo "could not get transaction code (code $ret)"
        exit -2
    fi
else
    echo "failed on transaction code get (code $resp)"
    exit -1
fi

#
# We have a good transaction code, let build the rest of the message and authentication
#
#
# Get current timestamp
#
tstamp=$(timestamp)
#
# event type  (we fix this example to status, could be video,audio,pir, or others
#
eventtype="status"
#
# devicetype, set to all zeros for now
#
devicetype="00:00:00:00:00:00:00:00:00"
#
# calculate transaction hash
#
transaction_hash=$(hash_hmac sha1 "${transaction_code}${uid}${devicetype}${eventtype}${tstamp}${msg}${status}" "$secret")
#
# Calculate Encryption Key
#
encryption_key=$(hash_hmac_key md5 "${transaction_code}" "${secret}")
#
# (0) send notification (1) get token (2) send notification with token
#
case $type in
    "0")
        #
        # No Encryption, just send authenticated notificaiton
        #
        URL="${API_SEND_EVENT}transaction_code=${transaction_code}&uid=${uid}&device_type=${devicetype}&event_type=${eventtype}&timestamp=${tstamp}&message=${msg}&status=${status}&transaction_hash=${transaction_hash}"
        resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" $URL)
        ret=$(xmlval "$(cat $OUTPUT)" "status")
        echo "$resp $ret"
    ;;

    "1")
        #
        # Send RC4 Encrypted notification
        #
        #
        # Calculate encryption key
        #
        encryption_key=$(hash_hmac_key md5 "${transaction_code}" "${secret}")
        #echo "encryption key = $encryption_key"

        #
        # Calculate encrypted string, use ~ instead of = so server side can parse easier (base64 can contain =)
        #
        edata=$(encrypt_rc4 "$encryption_key" "uid~${uid}&device_type~${devicetype}&event_type~${eventtype}&timestamp~${tstamp}&message~${msg}&status~${status}&transaction_hash~${transaction_hash}");
        #echo "ecrypypted string $edata"
        edata=$(urlencode "$edata")
        #echo "ecrypypted string $edata"
        #
        # Send unencrypted notificaiton
        #
        URL="${API_SEND_EVENT_AUTH}transaction_code=${transaction_code}&uid=${uid}&rc4=${edata}"
        resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" $URL)
        ret=$(xmlval "$(cat $OUTPUT)" "status")
        echo "$resp $ret"
    ;;

    "2")

    ;;

esac
rm $OUTPUT

# flush multiple returns
echo
EOF
sudo chmod +x $NOTIFIER
sudo mv ./$NOTIFIER $BIN_DIR
}
######### End Install Notifier #########

######### Install Send Notification #########
installSendNotification()
{
cat > send_notification.sh <<'EOF'
#!/bin/sh

#The weaved.conf file from which the SECRET is extracted
CONFIG_FILE=/etc/weaved/services/http.conf

#This is where notify.sh script resides
NOTIFY_DIR=/usr/bin

#notify.sh absolute path
NOTIFY_SCRIPT=/usr/bin/notify.sh

CMD_SUCCEED=0
ERR_FILE=1
INV_TYPE=2
ERR_SECRET=4

SECRET="$(cat $CONFIG_FILE | grep '\<password\>' | sed -n '2p' | cut -d ' ' -f2)"
UID="$(cat $CONFIG_FILE | grep '\<UID\>' | sed -n '2p' | cut -d ' ' -f2)"

echo $SECRET
echo $UID
###################################################################
#This, if other 3 values(TYPE, MSG, STATUS) are sent as arguments
###################################################################

REQ_NO_OF_ARGS=3

if [ "$#" -ne $REQ_NO_OF_ARGS ]
then
    echo "Expected Arguments : TYPE MSG STATUS "
fi

if [ "$1" ]
then
    if [ "$1" -eq 0 ] || [ "$1" -eq 1 ] || [ "$1" -eq 2 ]
    then
        TYPE=$1
    else
        echo "INVALID 'TYPE' VALUE"	#(arg1)
        echo $TYPE
        exit $INV_TYPE
    fi
else
    TYPE='Unknown'
    echo $TYPE
    echo "No TYPE Value Specified"
    exit $INV_TYPE
fi

# Check for UID
if [ "$2" ]
then 
    MSG=$2
else
    MSG="NO_Message_Recorded"
fi

# Check for Status string
if [ "$3" ]
then
    STATUS=$3
else
    STATUS="NO_Status_Recorded"
fi


# check for Secret; password size is 21 bytes
if [ -z $SECRET ]
then
    echo $SECRET
    echo "Password/Secret is not found"
    SECRET='Unidentified'
    exit $ERR_SECRET
fi

###################################################################
#If args not passed, used for testing purpose
#------------for test Purpose----------------
#       TYPE=0
#       MSG="HelloWorld"
#       STATUS="OK"
#       SECRET="9DA1FDA695387EFC5D4709C3BB898368DBE95610"
####################################################################

#Activating notify.sh script

if [ ! -s $NOTIFY_DIR ]
then
    echo "$NOTIFY_DIR Missing"
    sudo mkdir $NOTIFY_DIR
fi

if [ ! -s $NOTIFY_SCRIPT ]
then
        echo "unable to run notify.sh"
        exit $ERR_FILE
fi

sudo chmod +x $NOTIFY_SCRIPT 

#running the notify script

$NOTIFY_SCRIPT $TYPE $UID $SECRET $MSG $STATUS
if [ "$?" != "$CMD_SUCCEED" ]
then
        echo "Some Illegal changes were made to $NOTIFY_SCRIPT"
        exit $ERR_FILE
fi

exit
EOF
sudo chmod +x send_notification.sh
sudo mv send_notification.sh $BIN_DIR
}
######### End Install Send Notification #########

######### Service Install #########
installWeavedConnectd()
{

    sudo chmod +x ./bin/$DAEMON.$PLATFORM
    sudo cp ./bin/$DAEMON.$PLATFORM $BIN_DIR/$DAEMON
}
######### End Service Install #########

######### Install Start/Stop Sripts #########
installStartStop()
{
# Create init script
cat > $WEAVED_PORT.init <<'EOF'
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
EOF

sudo mv $WEAVED_PORT.init $INIT_DIR/$WEAVED_PORT
sudo chmod +x $INIT_DIR/$WEAVED_PORT

# Add startup levels
sudo update-rc.d $WEAVED_PORT defaults
levels="0 1 2 3 4 5 6"
for level in $levels; do
    sudo rm -f /etc/rc$level.d/*$WEAVED_PORT
done

start="2 3 4 5"
for i in $start; do
    sudo ln -sf $INIT_DIR/$WEAVED_PORT /etc/rc$i.d/S20$WEAVED_PORT
done

stop="0 1 6"
for i in $stop; do
    sudo ln -sf $INIT_DIR/$WEAVED_PORT /etc/rc$i.d/K01$WEAVED_PORT
done

# Startup the connectd daemon
printf "\n\n"
printf "*** Installation of weavedConnectd daemon has completed \n"
printf "*** and we are now starting the service. Please be sure to \n"
printf "*** register your device. \n\n"
printf "Now starting the weavedConnectd daemon..."
printf "\n\n"
sudo $INIT_DIR/$WEAVED_PORT start
printf "\n\n"
}
######### End Start/Stop Sripts #########

######### Check Running Service #########
checkDaemon()
{
    sleep 10
    checkMessages=$(sudo tail -n 2 $SYSLOG | grep "Server Connection changed to state 5")
    if [ "$checkMessages" = "" ]; then
        clear
        printf "Something is wrong and weavedConnectd doesn't appear to be running. \n"
        printf "We're going to exit now... \n"
        exit
        else
        clear
        printf "Congratulations! \n\n"
        printf "You've successfully installed Weaved services for $WEAVED_PORT. \n"
    fi
}
######### End Check Running Service #########

######### Register Device #########
registerDevice()
{
    unregdeviceStream=$(curl -s -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token" "$unregdevicelistURL")
    echo $unregdeviceStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep fulladdress | sed 's/"//g' | awk -F "fulladdress" '{print $2}'  | cut -c 2- > .unregdevList
    uid=$(awk "NR==1" .unregdevList)
    deviceCheck=$(cat .unregdevList | grep "No devices available")
    if [ "$deviceCheck" != "" ]; then
        clear
        printf "Something went wrong and your device is not showing in the portal. \n"
        printf "We're exiting the installer. Please go to https://forum.weaved.com for help. \n"
        exit
        else
        clear
        printf "We will now register your device with the Weaved backend services. \n"
        printf "Please provide an alias for your device: \n"
        read alias
        if [ "$alias" != "" ]; then
            printf "Your device with UID of $uid is now being provisioned... \n"
            curl -s -i -H "Content-Type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token" -d "{\"deviceaddress\": \"$uid\", \"devicealias\": \"$alias\" }" $regdeviceURL
            printf "\n\n\n"
        else
            registerDevice
        fi
    fi
    regCheck=$(cat $WEAVED_DIR/services/$WEAVED_PORT.conf | grep -c password)
    if [ -e $WEAVED_DIR/services/$WEAVED_PORT.conf ] && [ "$regCheck" = "2" ]; then
        clear
        printf "Looks like things provisioned properly and your device is now registered \n "
    elif [ "$regCheck" = "0" ]; then
            printf "The provisioning process has failed and a password or secret was not successfully written to $WEAVED_DIR/services/$WEAVED_PORT.conf. \n"
            printf "Now gathering debug information for you to send to forum@weaved.com: \n"
            printf "This is the syslog file output \n" > register_failure.log
            tail -n 15 $SYSLOG >> register_failure.log
            printf "\n" >> register_failure.log
            cat $WEAVED_DIR/services/$WEAVED_PORT.conf >> register_failure.log
    fi
}
######### End Register Device #########

######### Main Program #########
main()
{
    clear
    bashCheck
    checkForPriorInstalls
    userLogin
    testLogin
    installEnablement
    installNotifier
    installSendNotification
    installWeavedConnectd
    installStartStop
    checkDaemon
    registerDevice
    exit
}
######### End Main Program #########
main

