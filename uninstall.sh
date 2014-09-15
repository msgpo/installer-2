#! /bin/bash

sudo /etc/init.d/weavedConnectd stop
sudo rm -rf /etc/weaved
sudo rm -r /usr/bin/weavedConnectd
sudo rm -r /usr/bin/notify.sh
sudo rm -rf ~/.weaved
sudo rm /etc/init.d/weavedConnectd
sudo rm /var/run/weavedConnectd.pid

start="2 3 4 5"
for i in $start; do
  sudo rm -f /etc/rc$i.d/S20weavedConnectd
done

stop="0 1 6"
for i in $stop; do
  sudo rm -f /etc/rc$i.d/K01weavedConnectd
done

sudo rm -f ~/weaved_iot_kit_installer.tar.gz

printf "\n\n"
