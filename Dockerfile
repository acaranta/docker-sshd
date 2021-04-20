FROM jlesage/baseimage-gui:ubuntu-18.04


RUN apt-get update && apt-get install -y terminator tmux git openssh-server busybox-syslogd sudo iputils-ping vim && apt-get clean
RUN apt-get install -y software-properties-common && \
     add-apt-repository -y ppa:x2go/stable && \
     apt-get update && \
     DEBIAN_FRONTEND=noninteractive apt-get install -y \
         x2goserver x2goserver-xsession ttf-dejavu fonts-ipafont-gothic \
         openbox obconf obmenu conky nitrogen
RUN /bin/rm -v /etc/ssh/ssh_host_* && mkdir /var/run/sshd
COPY sshd_config /etc/ssh/
RUN mkdir /app
COPY terminator.png /app
#RUN APP_ICON_URL=file:///app/terminator.png && install_app_icon.sh "$APP_ICON_URL"
RUN mkdir /var/empty ; \
    chown root:sys /var/empty ; \
    chmod 755 /var/empty ; \
    groupadd sshd 
# ;  \
#    useradd -g sshd -c 'sshd privsep' -d /var/empty -s /bin/false sshd 
ENV APP_NAME="Terminator"
USER root
ADD startapp.sh /startapp.sh
