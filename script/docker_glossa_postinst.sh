#!/bin/sh

. script/docker_build_conf.sh

set -ve

# All permanent data must be under /corpora, which is a place to mount a data volume
mkdir -p /usr/local/share/cwb
ln -s /corpora/cwb_reg /usr/local/share/cwb/registry
mkdir -p /glossa/public
ln -s /corpora/media /glossa/public/media

# All temporary directories must be owned by glossa
mkdir -p /glossa/tmp /glossa/log
chown glossa /glossa/tmp /glossa/log
ln -s /corpora/import /glossa/tmp/dumps
mkdir -p /glossa/public/tmp_waveforms
chown glossa /glossa/public/tmp_waveforms /glossa/db/schema.rb

# Install gems that are newer than in glossa-base and clear the cache
apt-get update
$install $GEM_BUILD_DEPS
bundle install
rm -rf /var/lib/gems/*/cache/*
find /var/lib/gems/2.0.0/gems/ -name '*.o' -print0 |xargs -0 rm -f
$remove $GEM_BUILD_DEPS
$autoremove
rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin
rm -rf /var/lib/apt/lists

# This image is not supposed to be directly upgraded, so we can save a few
# dozens of MB by removing the git history:
rm -rf /var/lib/gems/*/bundler/gems/*/.git
