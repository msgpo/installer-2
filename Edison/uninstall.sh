# Weaved, Inc. Service uninstaller for Intel Edison.
# Tested on January 10, 2015 Yocto Linux release
# This automatically uninstalls daemons for http on port 80
# and SSH on port 22, along with notification scripts.

echo Weaved Uninstaller for Edison will now remove services for:
echo - http on port 80
echo - SSH on port 22
echo "Do you wish to continue? (Y/N)"
read word
case $word in
        [Yy]* )
                echo Removing Weaved software...
                ;;
        [Nn]* )
                echo Exiting...
                exit
                ;;
        * )
                echo Exiting...
                exit
                ;;
esac

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
