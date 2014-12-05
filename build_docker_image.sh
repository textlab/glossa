#!/bin/sh

set -e
bundle update --source rglossa rglossa-r rglossa-fcs
rake railties:install:migrations   # installs migrations for all engines
rake rglossa:install:thor

rm_dockerfile() {
  if [ -h Dockerfile ]; then rm -f Dockerfile; fi
}

set +e
if [ "$1" = "--full" ]; then
  rm_dockerfile
  ln -s Dockerfile.glossa-base Dockerfile || exit 1
  docker build -t textlab/glossa-base . || { rm -f Dockerfile; exit 1; }
fi
rm_dockerfile
ln -s Dockerfile.glossa Dockerfile || exit 1
docker build -t textlab/glossa . || { rm -f Dockerfile; exit 1; }
rm_dockerfile
