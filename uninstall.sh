#! /bin/bash

sudo /etc/init.d/weavedConnectd stop
sudo rm -rf /etc/weaved
sudo rm -r /usr/bin/weavedConnectd
sudo rm -r /usr/bin/notify.sh
sudo rm -rf ~/.weaved
sudo rm /etc/init.d/weavedConnectd
printf "\n\n"
