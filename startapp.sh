#!/bin/sh
[ ! -e /etc/ssh/ssh_host_rsa_key ] && dpkg-reconfigure openssh-server

[ "$USERNAME" = "" ] && USERNAME=user
[ "$USERID" = "" ] && USERID=1000
[ "$GROUPID" = "" ] && GROUPID=1000
[ "$USERSHELL" = "" ] && USERSHELL=/bin/bash
[ "$USERDIR" = "" ] && USERDIR="/home/$USERNAME"

echo "Creating user $USERNAME"
useradd $USERNAME

echo "Checking group $USERNAME"
groupmod -g "$GROUPID" "$USERNAME"

echo "Checking data directory $USERDIR"
[ ! -e "$USERDIR" ] && mkdir -p "$USERDIR" && chown "$USERID":"$GROUPID" "$USERDIR"

echo "Configuring user $USERNAME (uid=$USERID,gid=$GROUPID,dir=$USERDIR)"
usermod -u $USERID -o -g $GROUPID -d $USERDIR -s "$USERSHELL" $USERNAME

# Password
if [ "$PASSWORD" != "" ]
then
  echo "Setting $USERNAME password"
  usermod -p $(openssl passwd "$PASSWORD") "$USERNAME"
  sed -i 's/PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  echo '================================================================='
  echo ' Warning : Using a password is less secure than using a SSH key !'
  echo '================================================================='
else
  sed -i 's/PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi
echo "sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin" >>/etc/passwd
echo "sshd:x:74:" >>/etc/group

# Public key
if [ "$PUBKEY" != "" ]
then
  mkdir -p "$USERDIR/.ssh"
  chmod 700 "$USERDIR/.ssh"
  chown "$USERID":"$GROUPID" "$USERDIR/.ssh"
  echo "$PUBKEY" > "$USERDIR/.ssh/authorized_keys"
fi

# Sudo
sed -i '/'"$USERNAME"' ALL=.*/d' /etc/sudoers
case "$SUDOER" in
  yes)
    echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers
    ;;
  nopasswd)
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    ;;
  *)
    echo "No sudo power allowed"
esac

service ssh start
syslogd -n -O /dev/stdout &
>/var/lib/dpkg/statoverride
chmod a+rwx /tmp/run -Rfv
if [ -f "/home/$USERNAME/prerun.sh" ]; then
    /bin/bash /home/$USERNAME/prerun.sh
fi
exec su -c "cd $USERDIR ; XDG_CONFIG_HOME=$USERDIR/.config /usr/bin/terminator -u" $USERNAME
