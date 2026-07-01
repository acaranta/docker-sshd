#!/bin/sh
# Generate SSH host keys directly. `dpkg-reconfigure openssh-server` blocks on
# an interactive ucf prompt (our sshd_config differs from the package default),
# which would hang container startup.
[ ! -e /etc/ssh/ssh_host_rsa_key ] && ssh-keygen -A

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
# Note: no `-o/--non-unique` flag -- the base image's Rust usermod does not
# support it, and the target UID is free anyway.
usermod -u $USERID -g $GROUPID -d $USERDIR -s "$USERSHELL" $USERNAME

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

# The base image regenerates /etc/passwd and /etc/group at container startup, so
# the sshd privilege-separation user/group must be created here rather than in
# the Dockerfile (build-time entries get wiped). sshd refuses to start without it.
getent group sshd >/dev/null || groupadd sshd
getent passwd sshd >/dev/null || useradd -g sshd -c 'sshd privsep' -d /var/empty -s /bin/false sshd

service ssh start
syslogd -n -O /dev/stdout &
>/var/lib/dpkg/statoverride
chmod a+rwx /tmp/run -Rfv
if [ -f "/home/$USERNAME/prerun.sh" ]; then
    /bin/bash /home/$USERNAME/prerun.sh
fi
exec su -c "cd $USERDIR ; XDG_CONFIG_HOME=$USERDIR/.config /usr/bin/terminator -u" $USERNAME
