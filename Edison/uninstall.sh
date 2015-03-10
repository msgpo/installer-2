# Weaved, Inc. Service uninstaller for Intel Edison.
# Tested on January 10, 2015 Yocto Linux release
# This automatically uninstalls daemons for http on port 80
# and SSH on port 22, along with notification scripts.

stopWeaved.sh
systemctl disable weavedSSH.service
systemctl disable weavedHTTP.service
rm /lib/systemd/system/weaved*.service

rm /usr/bin/weavedConnectd.linux
rm /usr/bin/notify*.sh
rm /usr/bin/unregister.sh
rm /usr/bin/stopWeaved.sh
rm /usr/bin/startWeaved.sh
rm /usr/bin/Yo*
rm /usr/bin/bash

rm -rf /etc/weaved
