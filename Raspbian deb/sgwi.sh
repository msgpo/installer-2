#!/bin/sh
# sgwi.sh
# allows quick editing of the Weaved installer script on Ubuntu
# system and removing backup file to avoid warning/error

packageName=weavedconnectd-1.3-01
sudo gedit "$packageName"/usr/bin/weavedinstaller
sudo rm "$packageName"/usr/bin/weavedinstaller~

