#!/bin/bash

#  RPi_Installer.sh
#  
#
#  Created by Mike Young on 8/17/14.
#

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
TMP=~/.weaved
GIT=https://github.com/Weaved/Core
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
DAEMON=connectd
INIT_DIR=/etc/init.d

# Get connectd.conf file for the device project
# Requires user account and valid project on Portal
clear
echo "Please input your project code, followed by [ENTER]: "
echo -e "\n"
read project
echo -e "Your project code is $project\n"
if [ ! -d "WEAVED_DIR" ]; then
sudo mkdir $WEAVED_DIR
fi
sudo wget http://apiaws.yoics.net/v3/portal/members/downloadHandler.php?id=$project -O $WEAVED_DIR/connectd.conf

# Retrieve latest Weaved software from GitHub and install into proper locations
if [ ! -d "$TMP" ]; then
    mkdir $TMP
fi
cd $TMP
git clone $GIT
sudo cp $TMP/Core/binaries/$DAEMON.pi $BIN_DIR/$DAEMON
sudo cp $TMP/Core/startup_scripts/$DAEMON.init $INIT_DIR/$DAEMON

# Make files executable
sudo chmod +x $BIN_DIR/$DAEMON
sudo chmod +x $INIT_DIR/$DAEMON

# Startup the connectd daemon
sudo /etc/init.d/connectd start
