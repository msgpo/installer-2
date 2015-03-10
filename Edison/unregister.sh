#! /bin/bash
stopWeaved.sh
# restore the blank default enablement/configuration files
cp /etc/weaved/services/ssh.edison /etc/weaved/services/Weavedssh22.conf
cp /etc/weaved/services/web.edison /etc/weaved/services/Weavedhttp80.conf
ls -l /etc/weaved/services
sync
sleep 3

