#!/bin/bash

#  multi-installer.sh
#  
#
#  Weaved, Inc. Copyright 2014. All rights reserved.
#

##### Settings #####
VERSION=v1.2.5
AUTHOR="Mike Young"
MODIFIED="November 22, 2014"
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
filename=$(basename $0)
loginURL=https://api.weaved.com/api/user/login
unregdevicelistURL=https://api.weaved.com/api/device/list/unregistered
preregdeviceURL=https://api.weaved.com/v6/api/device/create
regdeviceURL=https://api.weaved.com/api/device/register
regdeviceURL2=http://api.weaved.com/v6/api/device/register
deleteURL=http://api.weaved.com/v6/api/device/delete
##### End Settings #####

displayVersion()
{
    printf "You are running installer script Version: $VERSION \n"
    printf "last modified on $MODIFIED. \n\n"
}

##### Platform detection #####
platformDetection()
{
    machineType=$(uname -m)
    osName=$(uname -s)
    if [ "$machineType" = "armv6l" ]; then
        PLATFORM=pi
        SYSLOG=/var/log/syslog
        elif [ "$machineType" = "armv7l" ]; then
            PLATFORM=beagle
            SYSLOG=/var/log/syslog
        elif [ "$machineType" = "x86_64" ] && [ "$osName" = "Linux" ]; then
            PLATFORM=linux
            if [ ! -f "/var/log/syslog" ]; then
                SYSLOG=/var/log/messages
            else
                SYSLOG=/var/log/syslog
            fi
        elif [ "$machineType" = "x86_64" ] && [ "$osName" = "Darwin" ]; then
            PLATFORM=macosx
            SYSLOG=/var/log/system.log
    else
        printf "Sorry, you are running this installer on an unsupported platform. But if you go to \n"
        printf "http://forum.weaved.com we'll be happy to help you get your platform up and running. \n\n"
        printf "Thanks!!! \n"
        exit
    fi

    printf "Detected platform type: $PLATFORM \n"
    printf "Using $SYSLOG for your log file \n\n"
}
##### End Syslog type #####

##### Protocol selection #####
protocolSelection()
{
    clear
    if [ "$PLATFORM" = "pi" ]; then
        printf "\n\n\n"
        printf "*********** Protocol Selection Menu ***********\n"
        printf "*                                             *\n"
        printf "*    1) WebSSH on default port 3066           *\n"
        printf "*    2) SSH on default port 22                *\n"
        printf "*    3) Web (HTTP) on default port 80         *\n"
        printf "*    4) WebIOPi on default port 8000          *\n"
        printf "*    5) Custom (TCP)                          *\n"
        printf "*                                             *\n"
        printf "***********************************************\n\n"
        unset get_num
        unset get_port
        while [[ ! ${get_num} =~ ^[0-9]+$ ]]; do
            echo "Please select from the above options (1-5):"
            read get_num
            ! [[ ${get_num} -ge 1 && ${get_num} -le 5  ]] && unset get_num
        done
        printf "You have selected: ${get_num}. \n\n"
        if [ "$get_num" = 4 ]; then
            PROTOCOL=webiopi
            PORT=8000
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 1 ]; then
            PROTOCOL=webssh
            PORT=3066
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 3 ]; then
            PROTOCOL=web
            PORT=80
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 2 ]; then
            PROTOCOL=ssh
            PORT=22
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 5 ]; then
            CUSTOM=1
            if ask "Is your protocol viewable through a web browser (e.g., HTTP running port 8080 vs. 80)"; then
                PROTOCOL=web
            else
                PROTOCOL=ssh
            fi
            printf "Please enter the protcol name (e.g., ssh, http, nfs): \n"
            read port_name
            CUSTOM_PROTOCOL=$(echo $port_name | tr '[A-Z]' '[a-z]' | tr -d ' ')
            while [[ ! ${get_port} =~ ^[0-9]+$ ]]; do
                printf "Please enter your desired port number (1-65536):"
                read get_port
                ! [[ ${get_port} -ge 1 && ${get_port} -le 65536  ]] && unset get_port
            done
            PORT=$get_port
            WEAVED_PORT=Weaved$CUSTOM_PROTOCOL$PORT
        fi
        printf "We will install Weaved services for the following:\n\n"
        if [ "$CUSTOM" = 1 ]; then
            printf "Protocol: $CUSTOM_PROTOCOL \n"
        else
            printf "Protocol: $PROTOCOL \n"
        fi
        printf "Port #: $PORT \n"
        printf "Service name: $WEAVED_PORT \n\n"

    elif [ "$PLATFORM" = "beagle" ] || [ "$PLATFORM" = "linux" ]; then
        printf "\n\n\n"
        printf "*********** Protocol Selection Menu ***********\n"
        printf "*                                             *\n"
        printf "*    1) WebSSH on default port 3066           *\n"
        printf "*    2) SSH on default port 22                *\n"
        printf "*    3) Web (HTTP) on default port 80         *\n"
        printf "*    4) Custom (TCP)                          *\n"
        printf "*                                             *\n"
        printf "***********************************************\n\n"
        unset get_num
        while [[ ! ${get_num} =~ ^[0-9]+$ ]]; do
            echo "Please select from the above options (1-4):"
            read get_num
            ! [[ ${get_num} -ge 1 && ${get_num} -le 4  ]] && unset get_num
        done
        printf "You have selected: ${get_num}. \n\n"
        if [ "$get_num" = 1 ]; then
            PROTOCOL=webssh
            PORT=3066
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 2 ]; then
            PROTOCOL=web
            PORT=80
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 3 ]; then
            PROTOCOL=ssh
            PORT=22
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 4 ]; then
            CUSTOM=1
            if ask "Is your protocol viewable through a web browser (e.g., HTTP running port 8080 vs. 80)"; then
                PROTOCOL=web
            else
                PROTOCOL=ssh
            fi
            printf "Please enter the protcol name (e.g., ssh, http, nfs): \n"
            read port_name
            CUSTOM_PROTOCOL=$(echo $port_name | tr '[A-Z]' '[a-z]' | tr -d ' ')
            while [[ ! ${get_port} =~ ^[0-9]+$ ]]; do
                printf "Please enter your desired port number (1-65536):"
                read get_port
                ! [[ ${get_port} -ge 1 && ${get_port} -le 65536  ]] && unset get_port
            done
            PORT=$get_port
            WEAVED_PORT=Weaved$CUSTOM_PROTOCOL$PORT
        fi
        printf "We will install Weaved services for the following:\n\n"
        if [ "$CUSTOM" = 1 ]; then
            printf "Protocol: $CUSTOM_PROTOCOL \n"
        else
            printf "Protocol: $PROTOCOL \n"
        fi
        printf "Port #: $PORT \n"
        printf "Service name: $WEAVED_PORT \n\n"
    elif [ "$PLATFORM" = "macosx" ]; then
        printf "\n\n\n"
        printf "*********** Protocol Selection Menu ***********\n"
        printf "*                                             *\n"
        printf "*    1) SSH on default port 22                *\n"
        printf "*    2) Web (HTTP) on default port 80         *\n"
        printf "*    3) Custom (TCP)                          *\n"
        printf "*                                             *\n"
        printf "***********************************************\n\n"
        unset get_num
        while [[ ! ${get_num} =~ ^[0-9]+$ ]]; do
            echo "Please select from the above options (1-3):"
            read get_num
            ! [[ ${get_num} -ge 1 && ${get_num} -le 3  ]] && unset get_num
        done
        printf "You have selected: ${get_num}. \n\n"
        if [ "$get_num" = 2 ]; then
            PROTOCOL=web
            PORT=80
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 1 ]; then
            PROTOCOL=ssh
            PORT=22
            WEAVED_PORT=Weaved$PROTOCOL$PORT
        elif [ "$get_num" = 3 ]; then
            if ask "Is your protocol viewable through a web browser (e.g., HTTP running port 8080 vs. 80)"; then
                PROTOCOL=web
            else
                PROTOCOL=ssh
            fi
            printf "Please enter the protcol name (e.g., ssh, http, nfs): \n"
            read port_name
            CUSTOM_PROTOCOL=$(echo $port_name | tr '[A-Z]' '[a-z]' | tr -d ' ')
            while [[ ! ${get_port} =~ ^[0-9]+$ ]]; do
                printf "Please enter your desired port number (1-65536):"
                read get_port
                ! [[ ${get_port} -ge 1 && ${get_port} -le 65536  ]] && unset get_port
            done
            CUSTOM=1
            PORT=$get_port
            WEAVED_PORT=Weaved$CUSTOM_PROTOCOL$PORT
        fi
        printf "We will install Weaved services for the following:\n\n"
        if [ "$CUSTOM" = 1 ]; then
            printf "Protocol: $CUSTOM_PROTOCOL \n"
        else
            printf "Protocol: $PROTOCOL \n"
        fi
        printf "Port #: $PORT \n"
        printf "Service name: $WEAVED_PORT \n\n"
    fi
}
##### End Protocol selection #####


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

#########  Check prior installs #########
checkForPriorInstalls()
{
    if [ -e "/usr/bin/$DAEMON" ]; then
        clear
        printf "It looks as if Weaved's services are already installed on this device. \n\n"
        if ask "Would you like to uninstall ALL Weaved software and services?"; then
            printf "\nUninstalling Weaved software and services... \n"
            deleteDevice
            if [ -f "$INIT_DIR/WebIOPi8000" ]; then
                instances=$(ls $INIT_DIR/Weaved* && $INIT_DIR/WebIOPi8000)
            else
                instances=$(ls $INIT_DIR/Weaved*)
            fi
            for i in $instances; do
                sudo $i stop
                sudo rm $i
                pid=$(echo $i | xargs basename).pid
                if [ -e "$PID_DIR/$pid" ]; then
                    sudo rm $PID_DIR/$pid
                fi
                start="2 3 4 5"
                for i in $start; do
                    if [ -e "/etc/rc$i.d/S20$WEAVED_PORT" ]; then
                        sudo rm -f /etc/rc$i.d/S20$WEAVED_PORT
                    fi
                done
                stop="0 1 6"
                for i in $stop; do
                    if [ -e /etc/rc$i.d/K01$WEAVED_PORT ]; then
                        sudo rm -f /etc/rc$i.d/K01$WEAVED_PORT
                    fi
                done
            done
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

            if [ -e $BIN_DIR/send_notification.sh ]; then
                sudo rm $BIN_DIR/send_notification.sh
                printf "$BIN_DIR/send_notification.sh now deleted \n\n"
                printf "Prior installation now removed. Now proceeding with new installation... \n"
            fi
            checkCron=$(sudo crontab -l | grep startweaved.sh | wc -l)
            if [ "checkCron" != 0 ]; then
                clear
                printf "We have detected a startweaved.sh entry in crontab. \n"
                if ask "Would you also like to remove your crontab entries? Select 'N' if unsure."; then
                    sudo crontab -e
                fi
            fi
            if [ -f "/etc/default/shellinabox" ]; then
                if ask "We've detected that you previously installed Shellinabox for WebSSH support. Do you wish to uninstall it?"; then
                    sudo apt-get -q -y --purge remove shellinabox
                    if [ -f "/etc/default/shellinabox" ]; then
                        sudo rm /etc/default/shellinabox
                        printf "Removing /etc/default/shellinabox... \n"
                    fi
                    if [ -f "/etc/init.d/shellinabox" ]; then
                        sudo rm /etc/init.d/shellinabox
                        printf "Removing /etc/init.d/shellinabox... \n"
                    fi
                fi
            fi
        else
            clear
            if ask "Would you like to selectively uninstall a specific service?"; then
                touch ./services.list
                if ls $INIT_DIR/Weaved* 1> /dev/null 2>&1; then
                    service_weaved=$(ls $INIT_DIR/Weaved* | xargs basename)
                    echo $service_weaved >> ./services.list
                fi
                if [ -f "/etc/init.d/WebIOPi8000" ]; then
                    service_webiopi=$(ls $INIT_DIR/WebIOPi8000 | xargs basename)
                    echo $service_webiopi >> ./services.list
                fi
                services=$(cat ./services.list)
                serviceNumber=$(cat ./services.list | wc -l)
                for i in $(seq 1 $serviceNumber); do
                    printf "$i\t $(awk "NR==$i" ./services.list) \n"
                done


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
#########  End Check prior installs #########

#########  Install WebSSH #########
installWebSSH()
{
    if [ "$PROTOCOL" = "webssh" ]; then
        clear
        printf "You have selected to install Weaved for WebSSH, which utilizes Shellinabox. \n"
        if ask "Would you like us to install and configure Shellinabox?"; then
            sudo apt-get -q -y install shellinabox
            printf "Copying... \n"
            sudo cp -vf ./scripts/shellinabox.default /etc/default/shellinabox
            sudo /etc/init.d/shellinabox restart
        fi
    fi
}
#########  End Install WebSSH #########

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

######### Install Enablement #########
installEnablement()
{
    if [ ! -d "WEAVED_DIR" ]; then
       sudo mkdir -p $WEAVED_DIR/services
    fi

    cat ./enablements/$PROTOCOL.$PLATFORM > ./$WEAVED_PORT.conf
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
    sed s/REPLACE/$WEAVED_PORT/ < ./scripts/send_notification.sh > ./send_notification.sh
    chmod +x ./send_notification.sh
    sudo mv ./send_notification.sh $BIN_DIR
    printf "Copied send_notification.sh to $BIN_DIR \n"
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
    if [ "$PLATFORM" != "macosx" ]; then
        sed s/WEAVED_PORT=/WEAVED_PORT=$WEAVED_PORT/ < ./scripts/init.sh > ./$WEAVED_PORT.init
        sudo mv ./$WEAVED_PORT.init $INIT_DIR/$WEAVED_PORT
        sudo chmod +x $INIT_DIR/$WEAVED_PORT
        # Add startup levels
        sudo update-rc.d $WEAVED_PORT defaults
        # Startup the connectd daemon
        printf "\n\n"
        printf "*** Installation of weavedConnectd daemon has completed \n"
        printf "*** and we are now starting the service. Please be sure to \n"
        printf "*** register your device. \n\n"
        printf "Now starting the weavedConnectd daemon..."
        printf "\n\n"
        if [ ! -e "/usr/bin/startweaved.sh" ]; then
            sudo cp ./scripts/startweaved.sh $BIN_DIR
            printf "startweaved.sh copied to $BIN_DIR\n"
        fi
        sudo $BIN_DIR/startweaved.sh
        checkCron=$(sudo crontab -l | grep startweaved.sh | wc -l)
        if [ "$checkCron" -lt 1 ]; then
            sudo crontab ./scripts/cront_boot.sh
        fi
        checkStartWeaved=$(cat $BIN_DIR/startweaved.sh | grep $WEAVED_PORT | wc -l)
        if [ "$checkStartWeaved" = 0 ]; then
            sed s/REPLACE_TEXT/$WEAVED_PORT/ < ./scripts/startweaved.add > ./startweaved.add
            sudo sh -c "cat startweaved.add >> /usr/bin/startweaved.sh"
            rm ./startweaved.add
        fi
        printf "\n\n"
    fi
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

######### Fetch UID #########
fetchUID()
{
    # Run weavedConnectd for 10 seconds to fetch UID
    printf "\n\n**** We will briefly run the Weaved service for 10 seconds to obtain a UID **** \n\n"
    ( cmdpid=$DAEMON; (sleep 10; killall $cmdpid) & $BIN_DIR/$DAEMON -f ./$WEAVED_PORT.conf )
}
######### End Fetch UID #########

######### Check for UID #########
checkUID()
{
    checkforUID=$(tail $WEAVED_PORT.conf | grep UID | wc -l)
    if [ "$checkforUID" = 2 ]; then
        sudo cp ./$WEAVED_PORT.conf /$WEAVED_DIR/services/
        uid=$(tail $WEAVED_DIR/services/$WEAVED_PORT.conf | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)
        printf "\n\nYour device UID has been successfully provisioned as: $uid. \n\n"
    else
        retryFetchUID
    fi
}
######### Check for UID #########

######### Retry Fetch UID ##########
retryFetchUID()
{
    for run in {1..5}
    do
        fetchUID
        checkforUID=$(tail $WEAVED_PORT.conf | grep UID | wc -l)
        if [ "$checkforUID" = 2 ]; then
            sudo cp ./$WEAVED_PORT.conf /$WEAVED_DIR/services/
            uid=$(tail $WEAVED_DIR/services/$WEAVED_PORT.conf | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)
            printf "\n\nYour device UID has been successfully provisioned as: $uid. \n\n"
            break
        fi
    done
    checkforUID=$(tail $WEAVED_PORT.conf | grep UID | wc -l)
    if [ "$checkforUID" != 2 ]; then
        printf "We have unsuccessfully retried to obtain a UID. Please contact Weaved Support at http://forum.weaved.com for more support.\n\n"
    fi
}
######### Retry Fetch UID ##########

######### Pre-register Device #########
preregisterUID()
{
    preregUID=$(curl -s $preregdeviceURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token")
    test1=$(echo $preregUID | grep "true" | wc -l)
    test2=$(echo $preregUID | grep -E "missing api token|api token missing" | wc -l)
    test3=$(echo $preregUID | grep "false" | wc -l)
    if [ "$test1" = 1 ]; then
        printf "Pre-registration of UID: $uid successful. \n\n"
    elif [ "$test2" = 1 ]; then
        printf "You are missing a valid session token and must be logged back in. \n"
        userLogin
        preregisterUID
    elif [ "$test3" = 1 ]; then
        printf "Sorry, but for some reason, the pre-registration of UID: $uid is failing. Please contact Weaved Support at http://forum.weaved.com.\n\n"
        exit
    fi
}
######### End Pre-register Device #########

######### Pre-register Device #########
getSecret()
{
    secretCall=$(curl -s $regdeviceURL2 -X 'POST' -d "{\"deviceaddress\":\"$uid\", \"devicealias\":\"$alias\", \"skipsecret\":\"true\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token")
    test1=$(echo $secretCall | grep "true" | wc -l)
    test2=$(echo $secretCall | grep -E "missing api token|api token missing" | wc -l)
    test3=$(echo $secretCall | grep "false" | wc -l)
    if [ "$test1" = 1 ]; then
        secret=$(echo $secretCall | awk -F "," '{print $2}' | awk -F "\"" '{print $4}' | sed s/://g)
        echo "# password - erase this line to unregister the device" >> ./$WEAVED_PORT.conf
        echo "password $secret" >> ./$WEAVED_PORT.conf
        sudo mv ./$WEAVED_PORT.conf $WEAVED_DIR/services/$WEAVED_PORT.conf
    elif [ "$test2" = 1 ]; then
        printf "You are missing a valid session token and must be logged back in. \n"
        userLogin
        getSecret
    elif [ "$test3" = 1 ]; then
        printf "Sorry, but we are having trouble registering your alias, so we will use $uid as your device name, instead. \n\n"
        alias=$uid
        getSecret
    fi
}
######### End Pre-register Device #########

######### Delete Device #########
deleteDevice()
{
    instances=$(ls $WEAVED_DIR/services/)
    for i in $instances; do
        uid=$(tail $WEAVED_DIR/services/$i | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)
        curl -s $deleteURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token"
    done
}
######### End Delete Device #########

######### Reg Message #########
regMsg()
{
    clear
    printf "********************************************************************************* \n"
    printf "CONGRATULATIONS! You are now registered with Weaved. \n"
    printf "Your registration information is as follows: \n\n"
    printf "Device alias: \n"
    printf "$alias \n\n"
    printf "Device UID: \n"
    printf "$uid \n\n"
    printf "Device secret: \n"
    printf "$secret \n\n"
    printf "The alias, Device UID and Device secret are kept in the License File: \n"
    printf "$WEAVED_DIR/services/$WEAVED_PORT.conf \n\n"
    printf "If you delete this License File, you will have to re-run the installation process. \n"
    printf "********************************************************************************* \n\n"
}
######### End Reg Message #########

######### Register Device #########
registerDevice()
{
    clear
    printf "We will now register your device with the Weaved backend services. \n"
    printf "Please provide an alias for your device: \n"
    read alias
    if [ "$alias" != "" ]; then
        printf "Your device will be called $alias. You can rename it later in the Weaved Portal. \n\n"
    else
        alias=$uid
        printf "For some reason, we're having problems using your desired alias. We will instead \n"
        printf "use $uid as your device alias, but you may change it via the web portal. \n\n"
    fi
}
######### End Register Device #########

######### Start Service #########
startService()
{
    sudo $INIT_DIR/$WEAVED_PORT stop
    if [ -e "$PID_DIR/$WEAVED_PORT.pid" ]; then
        sudo rm $PID_DIR/$WEAVED_PORT.pid
    fi
    sudo $INIT_DIR/$WEAVED_PORT start
}
######### End Start Service #########

######### Install Yo #########
installYo()
{
    sudo cp ./Yo $BIN_DIR
}
######### End Install Yo #########

######### Port Override #########
overridePort()
{
    if [ "$CUSTOM" = 1 ]; then
        cp $WEAVED_DIR/services/$WEAVED_PORT.conf ./
        echo "proxy_dest_port $PORT" >> ./$WEAVED_PORT.conf
        sudo mv ./$WEAVED_PORT.conf $WEAVED_DIR/services/
    fi
}
######### End Port Override #########


######### Main Program #########
main()
{
    clear
    displayVersion
    bashCheck
    userLogin
    testLogin
    platformDetection
    protocolSelection
    checkForPriorInstalls
    installWebSSH
    installEnablement
    installNotifier
    installSendNotification
    installWeavedConnectd
    installStartStop
    fetchUID
    checkUID
    preregisterUID
    registerDevice
    getSecret
    overridePort
    startService
    installYo
    regMsg
    exit
}
######### End Main Program #########
main