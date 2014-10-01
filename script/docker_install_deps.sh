#!/bin/sh

set -ve

# If you want to download Ubuntu packages or gems from another mirror, create
# script/set_build_mirrors.sh, setting appropriate values, e.g.:
# gem_mirror=http://192.168.59.3:9292
# ubuntu_mirror=http://ftp.uninett.no
[ -f script/set_build_mirrors.sh ] && . script/set_build_mirrors.sh || true

if [ "$ubuntu_mirror" != "" ]; then
  sed -i "s|http://archive.ubuntu.com|$ubuntu_mirror|g" /etc/apt/sources.list
fi
apt-get update
apt-get install --no-install-recommends -y git ruby2.0 sqlite3 libsqlite3-0 \
libmysqlclient18 libav-tools mp3splt tcl8.4 tk8.4 python-tk imagemagick xvfb

# FFmpeg is not available in this version of Ubuntu, so we're linking to
# avconv, which has similar command-line options
(cd /usr/local/bin; ln -s ../../bin/avconv ffmpeg)

# Set Ruby 2.0 to be the default version
(
  cd /usr/bin
  rm ruby gem irb rdoc erb; ln -s ruby2.0 ruby; ln -s gem2.0 gem
  ln -s irb2.0 irb; ln -s rdoc2.0 rdoc; ln -s erb2.0 erb
)
