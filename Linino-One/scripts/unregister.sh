#! /bin/sh
echo "Weaved Software unregister.sh"
read -p "Do you wish to factory reset (unregister) your Linino?" resp
if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
# stop running daemons
/etc/init.d/weavedSSH stop
/etc/init.d/weavedWEB stop
# overwrite any enablement files with factory reset versions
cp -rf ~/weaved/conf/*.conf /etc/weaved
echo "Device unregistered from Weaved"
fi
