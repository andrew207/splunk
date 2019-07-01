#!/bin/sh

# Enable arbitrary users 
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi
exec "$@"

# If Splunk is not downloaded (or wants a different version), download/install it.
# assumes string in the format "splunk-<version>-" exists in the URL
FILE=`echo $DOWNLOAD_URL | sed -r 's/^.+(splunk-[^-]+).+$/\1/g'`
if test -f "$FILE.tar.gz"; then
  echo "$FILE.tar.gz exists, no need to download again."
else
  echo "$FILE.tar.gz does not exist, downloading and installing/upgrading."
  wget -q -O /tmp/$FILE.tar.gz $DOWNLOAD_URL
  tar xzf /tmp/$FILE.tar.gz -C /opt
  PATH=$PATH:~/opt/splunk/bin
fi

# Fix "unusable filesystem" when Splunkd tries to create files
printf "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\n" >> $SPLUNK_HOME/etc/splunk-launch.conf

# Install apps from volume
yes | cp -rf /apps/* /opt/splunk/etc/apps

# Set admin password
printf '[user_info]\nUSERNAME = admin\nPASSWORD = %s' "$ADMIN_PASSWORD" > $SPLUNK_HOME/etc/system/local/user-seed.conf

# Run Splunk
/opt/splunk/bin/splunk start $SPLUNK_CLI_ARGS

# Keep dummy process running because Splunk can and will restart based on 
# user actions and we don't want the container to die. 
tail -f /dev/null