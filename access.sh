#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 6 ]; then
  echo "usage: server_user server server_ssh_port local_port destination destination_port"
  exit 1
fi

server_user=$1
server=$2
server_ssh_port=$3
local_port=$4
destination=$5
destination_port=$6

ssh $server_user@$server\
  -p $server_ssh_port -C -T -N\
  -L $local_port:$destination:$destination_port\
  -o ServerAliveInterval=120 -o ServerAliveCountMax=2\
  -o ConnectTimeout=10\
