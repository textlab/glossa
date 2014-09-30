# glossa
#
# VERSION               0.0.1

# Base image (https://registry.hub.docker.com/_/ubuntu/)
FROM ubuntu:14.04
MAINTAINER Anders Nøklestad <anders.noklestad@iln.uio.no>

# Install required packages
RUN apt-get update
RUN apt-get install -y autoconf bison flex gcc libc6-dev libglib2.0-dev \
  libncurses5-dev make g++ git ruby2.0 ruby2.0-dev sqlite3 libsqlite3-dev \
  libmysqlclient-dev libav-tools mp3splt tcl8.4-dev tk8.4-dev python-tk \
  imagemagick xvfb curl subversion

# Set Ruby 2.0 to be the default version
# From http://blog.costan.us/2014/04/restoring-ruby-20-on-ubuntu-1404.html
RUN rm /usr/bin/ruby /usr/bin/gem /usr/bin/irb /usr/bin/rdoc /usr/bin/erb && \
  ln -s /usr/bin/ruby2.0 /usr/bin/ruby && ln -s /usr/bin/gem2.0 /usr/bin/gem && \
  ln -s /usr/bin/irb2.0 /usr/bin/irb && ln -s /usr/bin/rdoc2.0 /usr/bin/rdoc && \
  ln -s /usr/bin/erb2.0 /usr/bin/erb && gem update --system && gem pristine --all

# FFmpeg is not available in this version of Ubuntu, so we're linking to
# avconv, which has similar command-line options
RUN cd /usr/local/bin && ln -s ../../bin/avconv ffmpeg

RUN gem install bundler

# Create directory from where the code will run
RUN mkdir -p /glossa
WORKDIR /glossa

# Make thin reachable to other containers
EXPOSE 3000

# Install the necessary gems
ADD Gemfile /glossa/Gemfile
ADD Gemfile.lock /glossa/Gemfile.lock
RUN bundle install

# Install the IMS Open Corpus Workbench (http://cwb.sourceforge.net/) by
# checking it out from svn and modifying config.mk to select linux-64 as the
# platform to build for. The -r option has the same function as Gemfile.lock
# for gems - it locks the code to a specific revision. When an update is
# needed, change it to the current date.
RUN svn export -r{2014-09-30} http://svn.code.sf.net/p/cwb/code/cwb/branches/3.0 /tmp/cwb && cd /tmp/cwb && \
  ruby -i -pe '$_.sub!(%r{ / [^/\r\n]+ \s* $ }x, "/linux-64") if $_.start_with? "include $(TOP)/config/platform/"' /tmp/cwb/config.mk && \
  make clean && make depend && make all && make install && \
  mkdir -p /usr/local/share/cwb/registry && \
  mkdir -p /usr/local/share/cwb/data

# Install the Snack Sound Toolkit
ADD config/waveforms.json /glossa/config/waveforms.json
WORKDIR /glossa
RUN SNACK_DIR="`ruby -rjson -e 'puts JSON.parse(File.read(%q{config/waveforms.json}))[%q{snack_dir}]'`" && \
  cd "`ruby -rbundler/setup -e 'puts Gem::Specification.find_by_name(%q{rglossa}).gem_dir'`/lib/waveforms" && \
  mkdir /tmp/snack && ./install_snack.sh "$SNACK_DIR" /usr/lib/tcl8.4 /usr/lib/tk8.4 /tmp/snack && \
  cd /tmp/snack/snack2.2.10/unix && make install exec_prefix="$SNACK_DIR" prefix="$SNACK_DIR" && \
  cd /tmp/snack/snack2.2.10/python && python2 setup.py install --prefix="$SNACK_DIR"

# Clean up
RUN rm -rf /tmp/snack /tmp/cwb

# Copy application code to container
ADD . /glossa/
WORKDIR /glossa

# Try not to add steps after the last ADD so we can use the
# Docker build cache more efficiently
