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
	# Set Splunk DB to volume directory
    printf "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\nSPLUNK_KB=/splunkdata" >> $SPLUNK_HOME/etc/splunk-launch.conf

    # Set admin password 
    printf '[user_info]\nUSERNAME = admin\nPASSWORD = %s' "$ADMIN_PASSWORD" > $SPLUNK_HOME/etc/system/local/user-seed.conf

    # Reduce/remove log noise:
    # splunkd hitting its own web interface
    # Splunk changing target indexer successfully 
    # deploymentserver phonehome successfully
    # Reduce historical log files from 5 to 1
    # TODO: remove UI access logs as kube-probe health checks hit them constantly and it's useless noise
    printf '[splunkd]\ncategory.HttpPubSubConnection=WARN\ncategory.UiHttpListener=ERROR\ncategory.TcpOutputProc=WARN\nappender.license_usage_maxBackupIndex=1\nappender.license_usage_summary.maxBackupIndex=1\nappender.metrics.maxBackupIndex=1\nappender.audittrail.maxBackupIndex=1\nappender.accesslog.maxBackupIndex=1\nappender.uiaccess.maxBackupIndex=1\nappender.scheduler.maxBackupIndex=1\nappender.remotesearches.maxBackupIndex=1\nappender.idata_ResourceUsage.maxBackupIndex=1\nappender.conf.maxBackupIndex=1\nappender.idata_DiskObjects.maxBackupIndex=1\nappender.idata_KVStore.maxBackupIndex=1\nappender.kvstore_appender.maxBackupIndex=1\nappender.idata_HttpEventCollector.maxBackupIndex=1\nappender.healthreporter.maxBackupIndex=1\nappender.watchdog_appender.maxBackupIndex=1' > $SPLUNK_HOME/etc/log-local.cfg
  
    # Disable monitoring console scheduled searches
    mkdir $SPLUNK_HOME/etc/apps/splunk_monitoring_console/local
    printf '[DMC Asset - Build Standalone Asset Table]\ndisabled = 1\n\n[DMC Asset - Build Standalone Computed Groups Only]\ndisabled = 1\n\n[DMC Asset - Build Full]\ndisabled = 1\n\n[DMC License Usage Data Cube]\ndisabled = 1' > $SPLUNK_HOME/etc/apps/splunk_monitoring_console/local/savedsearches.conf

    ## Disable hadoop archiver scheduled search
    mkdir $SPLUNK_HOME/etc/apps/splunk_archiver/local
    printf '[Bucket Copy Trigger]\ndisabled = 1' > $SPLUNK_HOME/etc/apps/splunk_archiver/local/savedsearches.conf
  fi
else
  echo "$FILE.tar.gz does not exist, was it correctly downloaded in the base image?"
fi

echo "Starting Splunkd..."

# Run Splunk
/opt/splunk/bin/splunk start $SPLUNK_CLI_ARGS

# Keep container running 
tail -f $SPLUNK_HOME/var/log/splunk/splunkd.log
