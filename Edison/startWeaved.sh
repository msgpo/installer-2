#! /bin/sh
systemctl start weavedSSH.service
systemctl start weavedHTTP.service
systemctl status weavedSSH.service
systemctl status weavedHTTP.service