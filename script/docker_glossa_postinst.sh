#!/bin/sh

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
bundle install
rm -rf /var/lib/gems/*/cache/*
