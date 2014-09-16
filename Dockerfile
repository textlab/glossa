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
  libmysqlclient-dev

# Set Ruby 2.0 to be the default version
# From http://blog.costan.us/2014/04/restoring-ruby-20-on-ubuntu-1404.html
RUN rm /usr/bin/ruby /usr/bin/gem /usr/bin/irb /usr/bin/rdoc /usr/bin/erb && \
  ln -s /usr/bin/ruby2.0 /usr/bin/ruby && ln -s /usr/bin/gem2.0 /usr/bin/gem && \
  ln -s /usr/bin/irb2.0 /usr/bin/irb && ln -s /usr/bin/rdoc2.0 /usr/bin/rdoc && \
  ln -s /usr/bin/erb2.0 /usr/bin/erb && gem update --system && gem pristine --all

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

# Install the IMS Open Corpus Workbench (http://cwb.sourceforge.net/)
# checked out from svn and with config.mk changed to select linux-64 as
# the platform to build for.
ADD cwb-3.0 /cwb-3.0
WORKDIR /cwb-3.0
RUN make clean && make depend && make all && make install \
  && mkdir -p /usr/local/share/cwb/registry \
  && mkdir -p /usr/local/share/cwb/data

# Copy application code to container
ADD . /glossa/
WORKDIR /glossa

# Try not to add steps after the last ADD so we can use the
# Docker build cache more efficiently
