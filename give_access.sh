#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 6 ]; then
  echo "usage: server_user server server_ssh_port server_tunnel_port destination destination_port"
  exit 1
fi

server_user=$1
server=$2
server_ssh_port=$3
server_tunnel_port=$4
destination=$5
destination_port=$6

echo "give access on $server: -R $server_tunnel_port:$destination:$destination_port"
ssh $server_user@$server\
  -p $server_ssh_port -C -T -N\
  -R $server_tunnel_port:$destination:$destination_port\
  -o ServerAliveInterval=120 -o ServerAliveCountMax=2\
  -o ConnectTimeout=10\

  # If need access without checking server key
  #-o StrictHostKeyChecking=no\
  #-o UserKnownHostsFile=/dev/null\
