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

# Make thin reachable to other containers
EXPOSE 3000

# Copy application code to container
ADD . /glossa/

# Try not to add steps after the last ADD so we can use the
# Docker build cache more efficiently
