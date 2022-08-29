#!/usr/bin/env bash
set -euo pipefail

rsync -av --delete public/ kopfkind@192.168.178.27:~/website-staging/
ssh kopfkind@192.168.178.27 '~/push-to-apache.sh'
echo "Sync to https://box.axelknauf.de/ done."

exit 0

