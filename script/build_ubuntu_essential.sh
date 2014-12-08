#!/bin/bash

docker rm ubuntu-essential-multilayer 2>/dev/null
set -ve
docker build -t textlab/ubuntu-essential-multilayer - <<'EOF'
FROM ubuntu:14.04
MAINTAINER Michał Kosek <michalkk@student.iln.uio.no>
RUN dpkg --clear-selections && \
    for pkg in apt libapt-pkg4.12 libstdc++6 ubuntu-keyring gnupg resolvconf; do \
      echo $pkg install |dpkg --set-selections; \
    done && \
    SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y dselect-upgrade && \
    dpkg-query -Wf '${db:Status-Abbrev}\t${binary:Package}\n' |grep '^.i' |awk -F'\t' '{print $2 " install"}' |dpkg --set-selections && \
    rm -r /var/cache/apt /var/lib/apt/lists
EOF
docker run --rm -i textlab/ubuntu-essential-multilayer tar zpc --exclude=/etc/hostname \
  --exclude=/etc/resolv.conf --exclude=/etc/hosts --one-file-system / >/tmp/ubuntu-essential.tar.gz
docker rmi textlab/ubuntu-essential-multilayer
docker import - textlab/ubuntu-essential-nocmd </tmp/ubuntu-essential.tar.gz
echo -e 'FROM textlab/ubuntu-essential-nocmd\nCMD /bin/bash' |docker build -t textlab/ubuntu-essential -
docker rmi textlab/ubuntu-essential-nocmd
