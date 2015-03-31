#!/bin/sh

set -e
if [ "$1" = "--full" ]; then
  bundle update
else
  bundle update --source rglossa rglossa-r rglossa-fcs
fi
rake railties:install:migrations   # installs migrations for all engines
rake rglossa:install:thor

rm_dockerfile() {
  if [ -h Dockerfile ]; then rm -f Dockerfile; fi
}

docker_build() {
  rm_dockerfile
  ln -s Dockerfile.$1 Dockerfile || exit 1
  docker build -t textlab/$1 . || { rm -f Dockerfile; exit 1; }
}

if [ "$1" = "--full" ]; then
  docker_build glossa-data
  docker_build glossa-base
fi
docker_build glossa
rm_dockerfile
