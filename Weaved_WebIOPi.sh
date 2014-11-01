#!/bin/bash

#  Weaved_WebIOPi.sh
#  
#
#  Weaved, Inc. Copyright 2014. All rights reserved.
#

##### Settings #####
VERSION=v1.1.5
PLATFORM=pi
WEAVED_PORT=WebIOPi8000
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

displayVersion()
{
    printf "Installer Script Version: $VERSION \n\n"
}

##### Platform detection #####
platformDetection()
{
    screening=$(uname -a | awk '{print $2}')
    if [ "$screening" = "raspberrypi" ]; then
        PLATFORM=pi
        elif [ "$screening" = "beaglebone" ]; then
            PLATFORM=beagle
        elif [ "$screening" = "ubuntu" ]; then
            PLATFORM=linux
    else
        printf "Sorry, you are running this installer on an unsupported platform. But if you go to \n"
        printf "http://forum.weaved.com we'll be happy to help you get your platform up and running. \n\n"
        printf "Thanks!!! \n"
        exit
    fi
}
##### End Platform detection #####

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
                sudo killall weavedConnectd
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
    displayVersion
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
    sudo chmod +x ./scripts/$NOTIFIER
    if [ ! -f $BIN_DIR/$NOTIFIER ]; then
        sudo cp ./scripts/$NOTIFIER $BIN_DIR
        printf "Copied $NOTIFIER to $BIN_DIR \n"
    fi
}
######### End Install Notifier #########

######### Install Send Notification #########
installSendNotification()
{
    sudo chmod +x ./scripts/send_notification.sh
    if [ ! -f $BIN_DIR/send_notification.sh ]; then
        sudo cp ./scripts/send_notification.sh $BIN_DIR
        printf "Copied send_notification.sh to $BIN_DIR \n"
    fi
}
######### End Install Send Notification #########

######### Service Install #########
installWeavedConnectd()
{
    if [ ! -f $BIN_DIR/$DAEMON ]; then
        sudo chmod +x ./bin/$DAEMON.$PLATFORM
        sudo cp ./bin/$DAEMON.$PLATFORM $BIN_DIR/$DAEMON
        printf "Copied $DAEMON to $BIN_DIR \n"
    fi
}
######### End Service Install #########

######### Install Start/Stop Sripts #########
installStartStop()
{
sudo cp ./scripts/init.sh $INIT_DIR/$WEAVED_PORT
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
    checkMessages=$(sudo tail $SYSLOG | grep "Server Connection changed to state 5" | wc -l)
    if [ "$checkMessages" = "1" ]; then
        clear
        printf "Congratulations! \n\n"
        printf "You've successfully installed Weaved services for $WEAVED_PORT. \n"
    else
        clear
        printf "Something is wrong and weavedConnectd doesn't appear to be running. \n"
        printf "We're going to exit now... \n"
        exit
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
            registerOutput=$(curl -s -i -H "Content-Type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token" -d "{\"deviceaddress\": \"$uid\", \"devicealias\": \"$alias\" }" $regdeviceURL)
            printf "\n\n\n"
        else
            registerDevice
        fi
    fi
    regCheck=$(cat $WEAVED_DIR/services/$WEAVED_PORT.conf | grep password | wc -l)
    regFail=$(echo $registerOutput | grep false | wc -l)
    regTrue=$(echo $registerOutput | grep true | wc -l)
#    if [ -e $WEAVED_DIR/services/$WEAVED_PORT.conf ] && [ "$regCheck" = "2" ]; then
#        clear
#        printf "Looks like things provisioned properly and your device is now registered \n "
#    elif [ "$regCheck" = "0" ]; then
#            printf "The provisioning process has failed and a password or secret was not successfully written to $WEAVED_DIR/services/$WEAVED_PORT.conf. \n"
#            printf "Now gathering debug information for you to send to forum@weaved.com: \n"
#            printf "This is the syslog file output \n" > register_failure.log
#            tail -n 15 $SYSLOG >> register_failure.log
#            printf "\n" >> register_failure.log
#            cat $WEAVED_DIR/services/$WEAVED_PORT.conf >> register_failure.log
#    fi
}
######### End Register Device #########

######### Install Test Registration #########
testRegistration()
{
    while [ "$regFail" = "1" ]; do
        clear
        printf "********************************************************************************* \n"
        printf "Registration attempt has failed. Looks like you may be using a previously \n"
        printf "assigned Alias. \n\n"
        printf "We will now try again. Please wait till prompted... \n"
        printf "********************************************************************************* \n\n"
        registerDevice
    done
    if [ "$regTrue" = "1" ] && [ "$regCheck" = "2" ]; then
        clear
        printf "********************************************************************************* \n"
        printf "GREAT NEWS!!! \n\n"
        printf "Your device is now fully registered. Please install the Weaved Connect App for \n"
        printf "iOS to complete your Weaved experience. \n"
        printf "********************************************************************************* \n\n"
    else
        clear
        printf "********************************************************************************* \n"
        printf "The registration portal returned a successful response, but a password has not been \n"
        printf "assigned to your $WEAVED_PORT.conf file. Please visit http://forum.weaved.com or \n"
        printf "send an email to forum@weaved.com. We will respond to you as quickly as possible to \n"
        printf "help get you up and running. \n\n"
        printf "Sorry for this inconvenience!\n"
        printf "********************************************************************************* \n\n"
    fi
}
######### End Install Test Registration #########

######### Install Email Services #########
installEmailNotification()
{
    if ask "May we turn on email notification to be used for notifying you of events or for sending diagnostic logs to Weaved Engineering in case of problems?"; then
        printf "Thank you! We are now installing email notification support. \n"
        printf "This will take a few minutes as we install dependent packages... \n"
        sudo apt-get update
        sudo apt-get install -y ssmtp
        sudo apt-get install -y mailutils
        sudo cp ./scripts/revaliases /etc/ssmtp/
        sudo cp ./scripts/ssmtp.conf /etc/ssmtp/
        printf "Installation of email notification services complete. \n"
    fi
}
######### End Install Email Services #########

######### Main Program #########
main()
{
    clear
#    platformDetection
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
    testRegistration
    exit
}
######### End Main Program #########
main
