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

# commit intermediate container to keep SSH key file inside it
docker build "$script_dir" -t reverse-tunnel-intermediate --target b
docker build "$script_dir" -t reverse-tunnel

authorized_keys=/home/$USER/.ssh/authorized_keys

echo "-------------------------------------------------"
echo "Running ssh server as $USER"
echo "Listening on port $ssh_port"
echo "Authorized destinations: $authorized_destinations"
echo "Authorized keys file: $authorized_keys"
echo "-------------------------------------------------"
echo "** Kill server using CTRL+\\ (sigquit) **"
echo "-------------------------------------------------"

terminal=
[ -t 1 ] && terminal="-it"

# only expose ssh port
docker run --rm=true -p $ssh_port:$ssh_port $terminal\
  -v $authorized_keys:$authorized_keys:ro\
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -u $(id -u)\
  reverse-tunnel\
  /app/sshd\
  -p $ssh_port\
  -D `: # stay in foreground`\
  -e `: # log on stdout`\
  -o ClientAliveInterval=180 `: #keep client alive`\
  -o ClientAliveCountMax=2\
  `: # restrict local tunneling to only some destinations`\
  `: # This is the heart of security!`\
  -o PermitOpen="$authorized_destinations"\
  `: # allow anyone to access forwarded ports and not only localhost`\
  -o GatewayPorts=yes\
  `: # only allow a specific user to connect (the one running container)`\
  -o AllowUsers="$USER"\
  `: # prevent execution of any command`\
  -o ForceCommand="/bin/true"\
  `: # other params (man sshd_config)`\
  -o UsePAM=no\
  -o PasswordAuthentication=no\
  -o AllowStreamLocalForwarding=no\
  -o AllowAgentForwarding=no\
  -o AllowTcpForwarding=yes\
  -o AuthenticationMethods=publickey\
  -o MaxAuthTries=1\
  -o PermitRootLogin=no\
  -o PermitTunnel=yes\
  -o PrintMotd=no\
  -o PidFile=none\
  || die "running server failed"
