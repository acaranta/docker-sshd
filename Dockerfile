FROM jlesage/baseimage-gui:ubuntu-26.04-v4


# The base image redirects /run -> /tmp/run and /var/log -> /config/log for a
# read-only rootfs. Those targets don't exist at build time, so the image's
# uutils (Rust) mkdir refuses to `mkdir -p` through the dangling symlinks
# (unlike GNU mkdir), which breaks systemd's package postinst scripts. Create
# the targets first so dependency configuration succeeds.
RUN mkdir -p /config/log /tmp/run
RUN apt update && apt install -y terminator tmux git openssh-server sudo iputils-ping vim && apt install -y busybox-syslogd && apt clean
RUN /bin/rm -v /etc/ssh/ssh_host_* && mkdir -p /var/run/sshd
COPY sshd_config /etc/ssh/
RUN mkdir /app
COPY terminator.png /app
RUN APP_ICON_URL=file:///app/terminator.png && install_app_icon.sh "$APP_ICON_URL"
RUN mkdir /var/empty ; \
    chown root:sys /var/empty ; \
    chmod 755 /var/empty ; \
    groupadd sshd 
# ;  \
#    useradd -g sshd -c 'sshd privsep' -d /var/empty -s /bin/false sshd 
ENV APP_NAME="Terminator"
USER root
ADD startapp.sh /startapp.sh
