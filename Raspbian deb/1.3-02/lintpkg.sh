#! /bin/sh
# lintpkg.sh
# script to build Debian package for Weaved Installer
# sorts out Lintian errors/warnings into individual
# text files
# also copies deb file to web server source folder
# in order to easily transfer to target device on
# LAN using wget
#
target=192.168.2.63
# target=76.103.130.46
pkgFolder=weavedconnectd-1.3-02
gzip -9 "$pkgFolder"/usr/share/doc/weavedconnectd/*.man
sudo chown root:root "$pkgFolder"/usr/share/doc/weavedconnectd/*.gz
dpkg-deb --build "$pkgFolder"
lintian -EviIL +pedantic "$pkgFolder".deb  > lintian-result.txt
grep E: lintian-result.txt > lintian-E.txt
grep W: lintian-result.txt > lintian-W.txt
grep I: lintian-result.txt > lintian-I.txt
grep X: lintian-result.txt > lintian-X.txt
sudo cp "$pkgFolder".deb /var/www
ls -l *.txt
scp ./$pkgFolder.deb pi@$target:/tmp/$pkgFolder.deb
