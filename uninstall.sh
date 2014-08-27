#! /bin/bash

sudo /etc/init.d/connectd stop
sudo rm -rf /etc/weaved
sudo rm -r /usr/bin/connectd
sudo rm -r /usr/bin/notify.sh
sudo rm -rf ~/.weaved
sudo rm /etc/init.d/connectd
printf "\n\n"
