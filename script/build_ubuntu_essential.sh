#!/bin/bash

docker rm ubuntu-essential-multilayer 2>/dev/null
set -ve
docker run --name ubuntu-essential-multilayer -i ubuntu:14.04 sh -c 'dpkg --clear-selections
for pkg in apt libapt-pkg4.12 libstdc++6 ubuntu-keyring gnupg resolvconf; do
  echo $pkg install |dpkg --set-selections
done
SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y dselect-upgrade
dpkg-query -Wf '\''${db:Status-Abbrev}\t${binary:Package}\n'\'' |grep "^.i" |awk -F"\\t" '\''{print $2 " install"}'\'' |dpkg --set-selections
apt-get update
apt-get -y install busybox-static
rm -r /var/cache/apt /var/lib/apt/lists'
docker commit ubuntu-essential-multilayer textlab/ubuntu-essential-multilayer
docker rm ubuntu-essential-multilayer
TMP_DIR=`mktemp -d`
docker run --rm -i textlab/ubuntu-essential-multilayer tar zpc --exclude=/etc/hostname \
  --exclude=/etc/resolv.conf --exclude=/etc/hosts --one-file-system / >"$TMP_DIR/ubuntu-essential.tar.gz"
docker rmi textlab/ubuntu-essential-multilayer
cd "$TMP_DIR"
tar zxf ubuntu-essential.tar.gz bin/busybox
echo -e 'FROM scratch\nADD bin/busybox /bin/busybox' >Dockerfile
docker build -t textlab/busybox-minimal .
set +e
docker rm ubuntu-essential 2>/dev/null
set -e
docker run -i --name ubuntu-essential textlab/busybox-minimal busybox tar zx <ubuntu-essential.tar.gz
docker commit ubuntu-essential textlab/ubuntu-essential-nocmd
docker rm ubuntu-essential
echo -e 'FROM textlab/ubuntu-essential-nocmd\nCMD /bin/bash' |docker build -t textlab/ubuntu-essential -
docker rmi textlab/ubuntu-essential-nocmd
rm -r "$TMP_DIR"
