#!/usr/bin/env bash

set -euo pipefail

cd $(readlink -f $(dirname $0))/..

if [ $# -ne 2 ]; then
  echo "usage: server_port client_port" >& 2
  exit 1
fi

server_port=$1
client_port=$2

s=dig-tunnel-$$

unset TMUX

tmux new -d -s $s ./server.sh $server_port localhost:*
err=1
while [ $err -eq 1 ]; do
  err=0
  echo "try connect to localhost:$server_port"
  sleep 1
  nc -z localhost $server_port || err=1
done
sleep 1
tmux split-window -t $s ./access.sh $USER localhost $server_port $client_port localhost $client_port
# put focus on server
tmux select-pane -t $s -U
tmux attach -t $s
