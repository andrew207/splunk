#!/bin/sh

# Enable arbitrary users in OpenShift
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi
exec "$@"

# If Splunk is not installed, install it
FILE=`echo $DOWNLOAD_URL | sed -r 's/^.+(splunk-[^-]+).+$/\1/g'`
if test -f "$FILE.tar.gz"; then
  echo "$FILE.tar.gz exists, no need to download again."
  if test -f "$SPLUNK_HOME/bin/splunk"; then
    echo "Splunk appears installed, no need to reinstall."
  else
    echo "Installing Splunk..."
    # Install Splunk and set PATH
    tar xzf $SPLUNK_HOME/$FILE.tar.gz -C /opt
    PATH=$PATH:~$SPLUNK_HOME/bin
	
	echo "Applying Docker optimisations..."
    
    # Fix "unusable filesystem" when Splunkd tries to create files
    printf "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\n" >> $SPLUNK_HOME/etc/splunk-launch.conf

    # Set admin password 
    printf '[user_info]\nUSERNAME = admin\nPASSWORD = %s' "$ADMIN_PASSWORD" > $SPLUNK_HOME/etc/system/local/user-seed.conf

    # Reduce log noise
    printf '[splunkd]\ncategory.HttpPubSubConnection=WARN\ncategory.UiHttpListener=ERROR' > $SPLUNK_HOME/etc/log-local.cfg
  fi
else
  echo "$FILE.tar.gz does not exist, was it correctly downloaded in the base image?"
fi

echo "Starting Splunkd..."

# Run Splunk
/opt/splunk/bin/splunk start $SPLUNK_CLI_ARGS

# Keep container running 
tail -f $SPLUNK_HOME/var/log/splunk/splunkd.log
