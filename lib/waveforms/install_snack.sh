#!/bin/bash

if [ "$#" -ne 4 ]; then
  >&2 echo "Usage: ./install_snack.sh snack_dir tcl_dir_list tk_dir_list tmp_dir"
  exit 1
fi

snack_dir="$1"
tcl_dir_list="$2"
tk_dir_list="$3"
tmp_dir="$4"

IFS=:
for dir in $tcl_dir_list; do
  tcl_dir="$dir"
  if [ -f "$dir/tclConfig.sh" ]; then
    break
  fi
done

for dir in $tk_dir_list; do
  tk_dir="$dir"
  if [ -f "$dir/tkConfig.sh" ]; then
    break
  fi
done
IFS=

if [ -d "$tmp_dir/snack2.2.10" ]; then
  >&2 echo "Delete '$tmp_dir/snack2.2.10' to continue"
  exit 1
fi

set -ve
[ -f "$tmp_dir/snack2.2.10.tar.gz" ] || curl http://www.speech.kth.se/snack/dist/snack2.2.10.tar.gz >"$tmp_dir/snack2.2.10.tar.gz"
(cd "$tmp_dir" && tar zxf snack2.2.10.tar.gz)
patch -d "$tmp_dir/snack2.2.10" -p1 <snack.patch
cd "$tmp_dir/snack2.2.10/unix"
./configure --exec-prefix="$snack_dir" --prefix="$snack_dir" --with-tcl="$tcl_dir" --with-tk="$tk_dir"
make
set +v

cat <<EOF

Switch, if needed, to the user with write permissions in '$snack_dir'.
Then run the following commands:

cd '$tmp_dir/snack2.2.10/unix' && make install exec_prefix='$snack_dir' prefix='$snack_dir'
cd '$tmp_dir/snack2.2.10/python' && python2 setup.py install --prefix='$snack_dir'

Afterwards, the directory '$tmp_dir' can be removed
EOF
