#!/bin/bash

#  RPi_Installer.sh
#  
#
#  Created by Mike Young on 8/17/14.
#

filename=RPi_Installer.sh

if [ "$BASH_VERSION" = '' ]; then
    printf "You executed this script with dash vs bash. \n"
    printf "Please re-run using \"./$filename\" or as \"bash $filename\". \n"
    exit
else
    clear
    echo "Now launching the Weaved connectd daemon installer..."
fi
clear

######### Begin Portal Login #########
userLogin () #Portal login function
{
printf "Please enter your Weaved Portal Username (email address): \n"
read username

printf "\nNow, please enter your password: \n"
read  -s password

loginURL=https://api.weaved.com/v3/api/user/login/$username/$password
projectsURL=https://api.weaved.com/v3/api/project/list/all

resp=$(curl -s -S -X GET \
    -H "content-type:application/json" \
    -H "apikey:WeavedDeveloperToolsWy98ayxR" \
    "$loginURL")

loginFailed=$(echo "$resp" | grep "login failed" | sed 's/"//g')
}
userLogin

# Retry if failed login
while [ "$loginFailed" != "" ]; do
    clear
    printf "You have entered either an incorrect username or password. Please try again. \n\n"
    userLogin
done
######### End Portal Login #########

######### Begin Get Project List #########
token=$(echo "$resp" | awk -F ":" '{print $3}' | awk -F "," '{print $1}' | sed -e 's/^"//'  -e 's/"$//')
projectsStream=$(curl -s -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token" "$projectsURL")

# Project Keys
projectKeys=$(echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep id | awk -F ":" '{print $2}' | sed 's/"//g')
echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep id | awk -F ":" '{print $2}' | sed 's/"//g' > .projectKeys

# Project Names
projectNames=$(echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep name | awk -F ":" '{print $2}' | sed 's/"//g')
echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep name | awk -F ":" '{print $2}' | sed 's/"//g' > .projectNames

# Project Versions
projectVersions=$(echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep version | awk -F ":" '{print $2}' | sed 's/"//g')
echo $projectsStream | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | tr -d "[]" | grep version | awk -F ":" '{print $2}' | sed 's/"//g' > .projectVersions

# Number of projects
projectNumber=$(echo "$projectKeys" | wc -l)

# Present Project details as selectable options
projectSelection ()
{
clear
printf "Please select the project from the following list, which you'd like to install: \n\n"

for i in $(seq 1 $projectNumber); do
    printf "$i\t $(awk "NR==$i" .projectNames)%-5s\t $(awk "NR==$i" .projectVersions)\t $(awk "NR==$i" .projectKeys)\t\n";
done
read select
}

if [ "$projectNumber" == 0 ]; then
    printf "You have not yet created any projects. Please visit our portal at http://developer.weaved.com and create a project. \n"
    printf "Thank you!"
    exit
else
    projectSelection
fi

while (( "$select" < 0 || "$select" > "$projectNumber" )); do
    printf "Please make a valid selection from the list above: \n"
    projectSelection
done

projectInstall=$(awk "NR==$select" .projectKeys)
printf "\nYou selected number $select, with the following project key: $projectInstall \n\n"

# Remove temp project files
rm -f .projectKeys .projectVersions .projectNames

######### End Get Project List #########

######### Begin project installation of Weaved connectd daemon #########
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
DAEMON=weavedConnectd
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d

printf "\n***** We are now installing Weaved's connectd daemon for your project... ***** \n\n"

if [ ! -d "WEAVED_DIR" ]; then
    sudo mkdir -p $WEAVED_DIR/services
fi
sudo wget http://apiaws.yoics.net/v3/portal/members/downloadHandler.php?id=$projectInstall -O $WEAVED_DIR/services/http.conf

# Retrieve latest Weaved software from GitHub and install into proper locations
if [ ! -d "$TMP" ]; then
    mkdir $TMP
fi
cd $TMP
git clone $GIT
sudo cp $TMP/Core/binaries/$DAEMON.pi $BIN_DIR/$DAEMON
sudo cp $TMP/Core/startup_scripts/$DAEMON.init $INIT_DIR/$DAEMON
sudo cp $TMP/Core/notification/$NOTIFIER $BIN_DIR

# Make files executable
sudo chmod +x $BIN_DIR/$DAEMON
sudo chmod +x $INIT_DIR/$DAEMON
sudo chmod +x $BIN_DIR/$NOTIFIER

# Add startup levels
#sudo update-rc.d $DAEMON defaults
start="2 3 4 5"
for i in $start; do
  ln -sf $INIT_DIR/$DAEMON /etc/rc$i.d/S20$DAEMON
done

stop="0 1 6"
for i in $stop; do
  ln -sf $INIT_DIR/$DAEMON /etc/rc$i.d/K01$DAEMON
done

# Startup the connectd daemon
printf "\n\n"
printf "*** Installation of Weaved's connectd daemon has completed \n"
printf "*** and we are now starting the service. Please be sure to \n"
printf "*** register your device. \n\n"
printf "Now starting the Weaved connectd daemon..."
printf "\n\n"
sudo /etc/init.d/$DAEMON start
printf "\n"

# Remove Git download
cp ~/.weaved/Core/binaries/weaved_web_install.tar.gz ~/.
rm -rf ~/.weaved
######### End project installation of weaved daemon #########
