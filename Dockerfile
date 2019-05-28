FROM ubuntu:xenial

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install sudo openssh-server busybox-syslogd vim screen less host inetutils-ping -y \
  && apt-get clean \
  && /bin/rm -v /etc/ssh/ssh_host_* \
  && mkdir /var/run/sshd
COPY sshd.sh /sshd.sh
COPY sshd_config /etc/sshd_config.orig
CMD /sshd.sh
