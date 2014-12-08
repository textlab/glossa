#!/bin/sh
if docker >/dev/null 2>&1; then
  run="sh -c"
else
  run="boot2docker ssh"
fi
$run "docker run --name glossa-data textlab/glossa-data >/dev/null 2>&1; true"
echo "Pulling glossa-base (it may take some time)"
$run "docker pull textlab/glossa-base"
echo "Starting Glossa..."
$run "docker run -d -p 61054:3000 --name glossa --volumes-from glossa-data textlab/glossa"
cwd="`dirname -- "$0"`"
if [ -f "$cwd/glossa_addr.sh" ]; then
  exec "$cwd/glossa_addr.sh"
fi
echo "Press Enter..."
read PAUSE
