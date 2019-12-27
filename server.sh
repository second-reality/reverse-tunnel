#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f $0))

die()
{
  echo "$@" >&2
  exit 1
}

if [ $# -lt 2 ]; then
  die "usage: port authorized_destinations[...]
example: ./server.sh 6666 localhost:* secret-server:22"
fi

ssh_port=$1
shift
authorized_destinations="$@"

docker build "$script_dir" -t reverse-tunnel

authorized_keys=/home/$USER/.ssh/authorized_keys

echo "-------------------------------------------------"
echo "Running ssh server as $USER"
echo "Listening on port $ssh_port"
echo "Authorized destinations: $authorized_destinations"
echo "Authorized keys file: $authorized_keys"
echo "-------------------------------------------------"

terminal=
[ -t 1 ] && terminal="-it"

# only expose ssh port
docker run --rm=true -p $ssh_port:$ssh_port $terminal\
  -v $authorized_keys:$authorized_keys:ro\
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -e SSH_PORT=$ssh_port\
  -e AUTHORIZED_DESTINATIONS="$authorized_destinations"\
  -e AUTHORIZED_USER="$USER"\
  -u $(id -u)\
  reverse-tunnel || die "running server failed"
