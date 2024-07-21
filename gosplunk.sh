#!/bin/bash

# Enable arbitrary users in OpenShift
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi
exec "$@"

# Set timezone
cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

# If Splunk is not installed, install it
FILE=`echo $DOWNLOAD_TARGET | sed -r 's/^.+(splunk-[^-]+).+$/\1/g'`
if test -f "$FILE.tar.gz"; then
  echo "$FILE.tar.gz exists, no need to download again."
  if test -f "$SPLUNK_HOME/bin/splunk"; then
    echo "Splunk appears installed, no need to reinstall."
  fi
else
  echo "$FILE.tar.gz does not exist, was it correctly downloaded in the base image? Killing container..."
  wget -q -O $SPLUNK_HOME/$FILE.tar.gz $DOWNLOAD_TARGET
  chgrp -R 0 ${SPLUNK_HOME}
  chmod -R g=u ${SPLUNK_HOME}
  chmod -R 755 ${SPLUNK_HOME}
  chgrp -R 0 /splunkdata
  chmod -R g=u /splunkdata
  chmod -R 755 /splunkdata
  chmod -R g=u /etc/passwd
  echo "Installing Splunk..."
  # Install Splunk and set PATH
  tar xzf $SPLUNK_HOME/$FILE.tar.gz -C /opt
  PATH=$PATH:~$SPLUNK_HOME/bin

  echo "Applying Docker optimisations..."

  # Fix "unusable filesystem" when Splunkd tries to create files
  # Set Splunk DB to volume directory
  printf "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\nSPLUNK_DB=/splunkdata" >> $SPLUNK_HOME/etc/splunk-launch.conf

  # Move KVStore to non-persistent directory due to permissions issues (key file permissions never set correctly when in volume)
  printf "\n[kvstore]\ndbPath = $SPLUNK_HOME/var/lib/splunk/kvstore" >> $SPLUNK_HOME/etc/system/local/server.conf

  # Set admin password
  printf '[user_info]\nUSERNAME = admin\nPASSWORD = %s' "$ADMIN_PASSWORD" > $SPLUNK_HOME/etc/system/local/user-seed.conf

  # Reduce/remove log noise:
  # splunkd hitting its own web interface
  # Splunk changing target indexer successfully
  # deploymentserver phonehome successfully
  # Reduce historical log files from 5 to 1
  printf '[splunkd]\ncategory.AutoLoadBalancedConnectionStrategy=WARN\ncategory.HttpPubSubConnection=WARN\ncategory.UiHttpListener=ERROR\ncategory.TcpOutputProc=WARN\nappender.license_usage_maxBackupIndex=1\nappender.license_>

  ## Disable hadoop archiver scheduled search
  mkdir $SPLUNK_HOME/etc/apps/splunk_archiver/local
  printf '[Bucket Copy Trigger]\ndisabled = 1' > $SPLUNK_HOME/etc/apps/splunk_archiver/local/savedsearches.conf

  ## Disable some other garbage you probably don't want - but can enable yourself if you want!
  mkdir -p /opt/splunk/etc/apps/splunk_assist/local
  printf '[install]\nallows_disable = true\nstate = disabled' | tee /opt/splunk/etc/apps/splunk_assist/local/app.conf

  ## Disable journald input as it's not relevant to our OS
  mkdir $SPLUNK_HOME/etc/apps/journald_input/local
  printf '[journald]\ndisabled = 1' > $SPLUNK_HOME/etc/apps/journald_input/local/inputs.conf
  printf '[install]\nstate = disabled' > $SPLUNK_HOME/etc/apps/journald_input/local/app.conf

fi

echo "Starting Splunkd..."

# Run Splunk
/opt/splunk/bin/splunk start $SPLUNK_CLI_ARGS

# Keep container running
tail -f $SPLUNK_HOME/var/log/splunk/splunkd.log
