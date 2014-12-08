#!/bin/bash

#  uninstaller.sh
#  
#
#  Weaved, Inc. Copyright 2014. All rights reserved.
#

##### Settings #####
VERSION=v1.2.6
AUTHOR="Mike Young"
MODIFIED="December 6, 2014"
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
filename=`basename $0`
loginURL=https://api.weaved.com/api/user/login
unregdevicelistURL=https://api.weaved.com/api/device/list/unregistered
preregdeviceURL=https://api.weaved.com/api/device/create
regdeviceURL=https://api.weaved.com/api/device/register
regdeviceURL2=http://api.weaved.com/api/device/register
deleteURL=http://api.weaved.com/api/device/delete
connectURL=http://api.weaved.com/api/device/connect
##### End Settings #####

#########  Check prior installs #########

##### Check for Bash #####
bashCheck()
{
    if [ "$BASH_VERSION" = '' ]; then
        clear
        printf "You executed this script with dash vs bash! \n\n"
        printf "Unfortunately, not all shells are the same. \n\n"
        printf "Please execute \"chmod +x "$filename"\" and then \n"
        printf "execute \"./"$filename"\".  \n\n"
        printf "Thank you! \n"
        exit
    else
        #clear
        echo "Now launching the Weaved connectd daemon installer..."
    fi
    #clear
}
##### End Bash Check #####

##### Version #####
displayVersion()
{
    printf "You are running installer script Version: %s \n" "$VERSION"
    printf "Last modified on %s, by %s. \n\n" "$MODIFIED" "$AUTHOR"
}
##### End Version #####

######### Begin Portal Login #########
userLogin () #Portal login function
{
    printf "\n\n\n"
    printf "Please enter your Weaved Username (email address): \n"
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

######### Delete Device #########
deleteDevice()
{
    instances="$(ls $WEAVED_DIR/services/)"
    for i in "$instances"; do
        uid="$(tail $WEAVED_DIR/services/$i | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)"
        curl -s $deleteURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token"
    done
}
######### End Delete Device #########

######### Check prior installs #########
checkForPriorInstalls()
{
    if [ -e "$BIN_DIR"/"$DAEMON" ]; then
        clear
        printf "It looks as if there's a previous version of Weaved's service installed for this protocol. \n\n"
        if ask "Would you like to uninstall ALL prior installation(s) before proceeding? "; then
            printf "\nUninstalling prior installation(s) of Weaved's services... \n"
            deleteDevice
            if [ -f "$INIT_DIR"/"WebIOPi8000" ]; then
                instances="$(ls "$INIT_DIR"/Weaved* && "$INIT_DIR"/WebIOPi8000)"
            else
                instances="$(ls "$INIT_DIR"/Weaved*)"
            fi
            for i in "$instances"; do
                sudo "$i" stop
                sudo rm "$i"
                pid="$(echo "$i" | xargs basename)".pid
                if [ -e "$PID_DIR"/"$pid" ]; then
                    sudo rm "$PID_DIR"/"$pid"
                fi
                start="2 3 4 5"
                for i in $start; do
                    if [ -e "/etc/rc$i.d/S20$WEAVED_PORT" ]; then
                        sudo rm -f /etc/rc"$i".d/S20"$WEAVED_PORT"
                    fi
                done
                stop="0 1 6"
                for i in $stop; do
                    if [ -e /etc/rc"$i".d/K01"$WEAVED_PORT" ]; then
                        sudo rm -f /etc/rc"$i".d/K01"$WEAVED_PORT"
                    fi
                done
            done
            if [ -d "$WEAVED_DIR" ]; then
                sudo rm -rf "$WEAVED_DIR"
                printf "%s now deleted \n" "$WEAVED_DIR"
            fi

            if [ -e "$BIN_DIR"/"$DAEMON" ]; then
                sudo rm -r "$BIN_DIR"/"$DAEMON"
                printf "%s/%s now deleted \n" "$BIN_DIR" "$DAEMON"
            fi

            if [ -e "$BIN_DIR"/"$NOTIFIER" ]; then
                sudo rm -r "$BIN_DIR"/"$NOTIFIER"
                printf "%s/%s now deleted \n" "$BIN_DIR" "$NOTIFIER"
            fi

            if [ -e $INIT_DIR/$WEAVED_PORT ]; then
                sudo rm $INIT_DIR/$WEAVED_PORT
                printf "%s/%s now deleted \n" "$INIT_DIR" "$WEAVED_PORT"
            fi

            if [ -e "$BIN_DIR"/send_notification.sh ]; then
                sudo rm "$BIN_DIR"/send_notification.sh
                printf "%s/send_notification.sh now deleted \n\n" "$BIN_DIR"
                printf "Prior installation now removed. Now proceeding with new installation... \n"
            fi
            checkCron="$(sudo crontab -l | grep startweaved.sh | wc -l)"
            if [ "checkCron" != 0 ]; then
                clear
                sudo crontab ./scripts/cront_blank.sh
            fi
            if [ -f "/etc/default/shellinabox" ]; then
                if ask "We've detected that you previously installed Shellinabox for WebSSH support. Do you wish to uninstall it?"; then
                    sudo apt-get -q -y --purge remove shellinabox
                    if [ -f "/etc/default/shellinabox" ]; then
                        sudo rm /etc/default/shellinabox
                        printf "Removing /etc/default/shellinabox... \n"
                    fi
                    if [ -f "/etc/init.d/shellinabox" ]; then
                        sudo rm "$INIT_DIR"/shellinabox
                        printf "Removing %s/shellinabox... \n" "$INIT_DIR"
                    fi
                fi
            fi
        else
            printf "\nYou've chosen not to remove your old installation files.  \n"
            printf "The following files will be either created or overwritten: \n\n"
            printf "%s/%s \n" "$BIN_DIR" "$DAEMON"
            printf "%s/services/%s.conf \n" "$WEAVED_DIR" "$WEAVED_PORT"
            printf "%s/%s \n" "$INIT_DIR" "$WEAVED_PORT"
            printf "%s/%s \n" "$BIN_DIR" "$NOTIFIER"
            printf "%s/%s.pid \n\n" "$PID_DIR" "$WEAVED_PORT"
        fi
    fi
}
#########  End Check prior installs #########

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
displayVersion
bashCheck
userLogin
testLogin
checkForPriorInstalls

