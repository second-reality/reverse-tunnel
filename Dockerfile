FROM debian:buster-slim

RUN apt update && apt install -y openssh-server

# allow any user to read ssh server key
RUN chmod a+r\
 /etc/ssh/ssh_host_rsa_key\
 /etc/ssh/ssh_host_ecdsa_key\
 /etc/ssh/ssh_host_ed25519_key

# run sshd on port $SSH_PORT, only allowing $AUTHORIZED_USER to connect
# and only authorizing forwarding to $AUTHORIZED_DESTINATIONS
# User running this is the one running the container
ENTRYPOINT /usr/sbin/sshd -p "$SSH_PORT" -D\
# show log of connections on stderr
 -e\
# keep clients alive
 -o ClientAliveInterval=180 -o ClientAliveCountMax=2\
# restrict local tunneling to only some destinations
# This is the heart of security!
 -o PermitOpen="$AUTHORIZED_DESTINATIONS"\
# allow anyone to access forwarded ports and not only localhost
 -o GatewayPorts=yes\
# only allow a specific user to connect (the one running container)
 -o AllowUsers="$AUTHORIZED_USER"\
# prevent execution of any command
 -o ForceCommand="/No/Shell/Available/ONLY_TUNNELING_IS_POSSIBLE"\
# other params (man sshd_config)
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
