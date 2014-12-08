#!/bin/sh
if boot2docker >/dev/null 2>&1; then
  IP=`boot2docker ip 2>/dev/null`
  run="boot2docker ssh"
else
  IP=127.0.0.1
  run="sh -c"
fi
PORT=`$run 'ID=$(docker ps |awk '\''$NF=="glossa"{print $1}'\'');
docker port "$ID" 2>/dev/null |awk -F: "{print \\\$2}"'`
echo
if [ "$PORT" = "" ]; then
  echo "Glossa is not running"
else
  echo "Glossa is available at:"
  echo "http://$IP:$PORT"
fi
echo "Press Enter..."
read PAUSE
