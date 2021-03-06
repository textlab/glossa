#!/bin/sh

set -ve

. script/docker_build_conf.sh

# Changes to these two files make the image unnecessarily large after running useradd:
rm -f /var/log/faillog /var/log/lastlog
useradd -u 61054 -d /glossa glossa

# Ensure that we will get the newest packages
apt-get update

# Temporarily enable caching - we may install and remove same packages a few times
mkdir -p /etc/apt/apt.conf.d/disabled
mv /etc/apt/apt.conf.d/docker-clean /etc/apt/apt.conf.d/disabled/
mv /etc/apt/apt.conf.d/01autoremove /etc/apt/apt.conf.d/disabled/

# Install the necessary gems
gem update --system && gem pristine --all && gem install bundler
rm -rf /root/.gem
$install $GEM_BUILD_DEPS
bundle install
$remove $GEM_BUILD_DEPS
$autoremove

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
find /var/lib/gems/2.0.0/gems/ -name '*.o' -print0 |xargs -0 rm -f

# Delete rglossa gems. They will change all the time, so there is no point in
# including them in the base image. The build script for textlab/glossa will
# run "bundle install" anyway, and will download their most recent versions.
rm -rf /var/lib/gems/*/bundler/gems/rglossa*

# Remove the suid/sgid bits from all files for increased security
find / -mount ! -type d -perm +6000 -print0 |xargs -0 chmod ug-s
