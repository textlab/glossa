#!/bin/sh

set -ve

install='apt-get install --no-install-recommends -y'
remove='apt-get purge --auto-remove -y'
autoremove='apt-get autoremove --purge -y'

# Build dependencies for the gems, Corpus Workbench and Snack
GEM_BUILD_DEPS='make patch binutils gcc g++ libc6-dev ruby2.0-dev libmysqlclient-dev libsqlite3-dev'
CWB_BUILD_DEPS='subversion autoconf bison flex libglib2.0-dev libncurses5-dev make binutils gcc g++ libc6-dev' 
SNACK_BUILD_DEPS='curl make patch binutils gcc g++ libc6-dev tcl8.4-dev tk8.4-dev'

# Changes to these two files make the image unnecessarily large after running useradd:
rm -f /var/log/faillog /var/log/lastlog
useradd -u 61054 -d /glossa glossa

# If you want to download Ubuntu packages or gems from another mirror, create
# script/set_build_mirrors.sh, setting appropriate values, e.g.:
# gem_mirror=http://192.168.59.3:9292
# ubuntu_mirror=http://ftp.uninett.no
[ -f script/set_build_mirrors.sh ] && . script/set_build_mirrors.sh || true

# Ensure that we will get the newest packages
apt-get update

# Temporarily enable caching - we may install and remove same packages a few times
mkdir -p /etc/apt/apt.conf.d/disabled
mv /etc/apt/apt.conf.d/docker-clean /etc/apt/apt.conf.d/disabled/
mv /etc/apt/apt.conf.d/01autoremove /etc/apt/apt.conf.d/disabled/

# Change the gem source, if needed
if [ "$gem_mirror" != "" ]; then
  sed -i "s|https://rubygems.org|$gem_mirror|g" Gemfile
  gem sources -a "$gem_mirror"
  gem sources -r https://rubygems.org/
fi

# Install the necessary gems
gem update --system && gem pristine --all && gem install bundler
$install $GEM_BUILD_DEPS
bundle install
$remove $GEM_BUILD_DEPS
$autoremove

# This directory contains rglossa gems. They will change all the time, so there
# is no point in including them in the base image. The build script for
# textlab/glossa will run "bundle install" anyway, and will download their most
# recent versions.
rm -rf /var/lib/gems/2.0.0/bundler/gems

# Install the IMS Open Corpus Workbench (http://cwb.sourceforge.net/) by
# checking it out from svn and modifying config.mk to select linux-64 as the
# platform to build for.
$install $CWB_BUILD_DEPS
svn export http://svn.code.sf.net/p/cwb/code/cwb/branches/3.0 /tmp/cwb
cd /tmp/cwb
ruby -i -pe '$_.sub!(%r{ / [^/\r\n]+ \s* $ }x, "/linux-64") if $_.start_with? "include $(TOP)/config/platform/"' /tmp/cwb/config.mk
make clean && make depend && make all && make install
$remove $CWB_BUILD_DEPS
$autoremove

# Install the Snack Sound Toolkit
cd /glossa
$install $SNACK_BUILD_DEPS
for dir in snack_dir tcl_dir tk_dir; do
  export $dir="`ruby -rjson <<EOF
    print JSON.parse(File.read(%q{config/waveforms.json}))[%q{$dir}]
EOF
`"
done
rglossa_dir="`ruby -rbundler/setup <<EOF
  print Gem::Specification.find_by_name(%q{rglossa}).gem_dir
EOF
`"
cd "$rglossa_dir/lib/waveforms"
mkdir /tmp/snack
./install_snack.sh "$snack_dir" "$tcl_dir" "$tk_dir" /tmp/snack
cd /tmp/snack/snack2.2.10/unix
make install exec_prefix="$snack_dir" prefix="$snack_dir"
cd /tmp/snack/snack2.2.10/python
python2 setup.py install --prefix="$snack_dir"
$remove $SNACK_BUILD_DEPS
$autoremove

# Disable caching and clean up
mv /etc/apt/apt.conf.d/disabled/* /etc/apt/apt.conf.d
$autoremove
rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin
rm -rf /tmp/snack /tmp/cwb /var/lib/gems/*/cache/* /var/lib/apt/lists

# Remove the suid/sgid bits from all files for increased security
find / -mount ! -type d -perm +6000 -print0 |xargs -0 chmod ug-s
