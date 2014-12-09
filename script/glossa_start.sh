#!/bin/sh
if docker >/dev/null 2>&1; then
  run="sh -c"
else
  run="boot2docker ssh"
fi

$run "docker run --name glossa-data textlab/glossa-data >/dev/null 2>&1; true"
$run "docker rm glossa >/dev/null 2>&1; true"
echo "Starting Glossa..."
if ! $run "docker images |grep -q '^textlab/glossa[ \t]'" 2>/dev/null; then
  echo "(first download may take some time)"
  PULL_GLOSSA_BASE=yes
fi

$run "docker run -d -p 61054:3000 --name glossa --volumes-from glossa-data textlab/glossa"
cwd="`dirname -- "$0"`"
if [ -f "$cwd/glossa_addr.sh" ]; then
  "$cwd/glossa_addr.sh" --no-pause
fi

if [ "$PULL_GLOSSA_BASE" = "yes" ]; then
  # Pull textlab/glossa-base. Not strictly necessary, but it will stay
  # there even if textlab/glossa is removed, and reduce upgrade time.
  $run "docker pull textlab/glossa-base"
fi
echo "Press Enter..."
read PAUSE
