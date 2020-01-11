FROM jlesage/baseimage-gui:ubuntu-18.04


RUN apt-get update && apt-get install -y terminator tmux git openssh-server busybox-syslogd sudo iputils-ping vim && apt-get clean
RUN /bin/rm -v /etc/ssh/ssh_host_* && mkdir /var/run/sshd
COPY sshd_config /etc/ssh/
RUN mkdir /app
COPY terminator.png /app
RUN APP_ICON_URL=file:///app/terminator.png && install_app_icon.sh "$APP_ICON_URL"
ENV APP_NAME="Terminator"
ADD startapp.sh /startapp.sh
