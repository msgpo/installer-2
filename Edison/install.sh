# Weaved, Inc. Service installer for Intel Edison.
# Tested on January 10, 2015 Yocto Linux release
# This automatically installs daemons for http on port 80
# and SSH on port 22, along with notification scripts.
# This needs to be used with the Weaved portal V9 or later
# registration feature.

VERSION=1.01
AUTHOR="Gary Worsham"
DATE="03/10/2105"

echo Weaved Installer for Edison will now install services for:
echo - http on port 80
echo - SSH on port 22
echo "Do you wish to continue? (Y/N)"
read word
case $word in
	[Yy]* )
		echo Installing...
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

cp weavedConnectd.linux /usr/bin
chmod +x /usr/bin/weavedConnectd.linux 

cp notify*.sh /usr/bin
chmod +x /usr/bin/notify*.sh

cp unregister.sh /usr/bin
chmod +x /usr/bin/unregister.sh

cp stopWeaved.sh /usr/bin
chmod +x /usr/bin/stopWeaved.sh

cp startWeaved.sh /usr/bin
chmod +x /usr/bin/startWeaved.sh

cp Yo* /usr/bin
chmod +x /usr/bin/Yo*

mkdir /etc/weaved
mkdir /etc/weaved/services

cp ssh.edison /etc/weaved/services/Weavedssh22.conf
cp ssh.edison /etc/weaved/services
cp web.edison /etc/weaved/services/Weavedhttp80.conf
cp web.edison /etc/weaved/services/

cp weaved*.service /lib/systemd/system
systemctl daemon-reload
startWeaved.sh
systemctl enable weavedSSH.service
systemctl enable weavedHTTP.service

