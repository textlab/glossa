#!/bin/sh

set -ve

apt-get update
apt-get install --no-install-recommends -y ruby2.0 sqlite3 libsqlite3-0 \
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

# Cleanup
rm -rf /var/lib/apt/lists
