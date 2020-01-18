FROM debian:buster AS b

RUN apt update && apt install -y openssh-server

# allow any user to read ssh server key
RUN chmod a+r\
 /etc/ssh/ssh_host_rsa_key\
 /etc/ssh/ssh_host_ecdsa_key\
 /etc/ssh/ssh_host_ed25519_key

RUN mkdir -p /tmp/deps
# to get libraries needed
# basically does what ldd does
RUN cp -v\
  $(LD_TRACE_LOADED_OBJECTS=1 /usr/sbin/sshd  | grep '=>' | cut -f 3 -d ' ')\
  /tmp/deps

FROM gcr.io/distroless/base-debian10
COPY --from=b /tmp/deps/* /lib/
COPY --from=b /etc/ssh/* /etc/ssh/
COPY --from=b /usr/sbin/sshd /app/
# create fake shell
# else sshd fails when connecting saying
# "User $USER not allowed because shell /bin/bash does not exist"
COPY --from=b /bin/true /bin/bash
COPY --from=b /bin/true /bin/zsh
