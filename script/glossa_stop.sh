#!/bin/sh
if docker >/dev/null 2>&1; then
  run="sh -c"
else
  run="boot2docker ssh"
fi

echo "Stopping Glossa..."
$run "docker stop glossa; docker rm glossa"
echo "Press Enter..."
read PAUSE
