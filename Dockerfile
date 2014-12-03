# glossa
#
# VERSION               0.0.1

# Base image (https://registry.hub.docker.com/_/ubuntu/)
FROM ubuntu:14.04
MAINTAINER Anders Nøklestad <anders.noklestad@iln.uio.no>, Michał Kosek <michalkk@student.iln.uio.no>

WORKDIR /glossa
ADD script/ /glossa/script/
RUN script/docker_install_deps.sh

ADD Gemfile /glossa/
ADD Gemfile.lock /glossa/
ADD config/waveforms.json /glossa/config/waveforms.json
RUN script/docker_build_deps.sh

RUN mkdir -p /usr/local/share/cwb && ln -s /corpora/cwb_reg /usr/local/share/cwb/registry
RUN mkdir -p /glossa/public && ln -s /corpora/media /glossa/public/media
RUN mkdir -p /glossa/tmp && ln -s /corpora/import /glossa/tmp/dumps

# Make thin reachable to other containers
EXPOSE 3000

# Run the application with an SQLite database
ENV DATABASE_URL sqlite3:////corpora/glossa.sqlite3
CMD rake db:migrate && rails server

# Copy application code to container
ADD . /glossa/

# Try not to add steps after the last ADD so we can use the
# Docker build cache more efficiently
