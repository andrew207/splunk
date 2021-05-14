# Splunk 
This is a Dockerfile for Splunk, currently running version 8.2.0 - https://www.splunk.com

It is based on Alpine Linux and supports OpenShift and unRAID.

It is designed to deploy Splunk Enterprise quickly and easily. The web interface is exposed on port HTTP/8000, data ingest on TCP/9997, and API on HTTPS/8089. 

If you run the Dockerfile with no arguments you will get a single instance of Splunk with the user admin:changeme2019. 

Compatible with Splunk 7.1.0 and newer. 

Be careful with your volumes as this container can get BIG. Make sure you make (at minimum) `/splunkdata` a volume to alleviate this if you're using the container for any extended amount of time.

# Usage
Single instance with no persistence 

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 --name splunk atunnecliffe/splunk`

Single instance with indexed data and config/app persistence in unRAID

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 -v '/mnt/user/appdata/splunk/splunkdata':'/splunkdata':'rw' -v '/mnt/user/appdata/splunk/etc/apps':'/opt/splunk/etc/apps':'rw' --name splunk atunnecliffe/splunk`

Install an older version (7.2.6) and change admin password

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 -e ADMIN_PASSWORD="mynewpassword" -e DOWNLOAD_URL="https://www.splunk.com/page/download_track?file=7.2.6/linux/splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=7.2.6&product=splunk&typed=release" -p 8000:8000 --name splunk atunnecliffe/splunk`

# Arguments

`SPLUNK_CLI_ARGS` 

What args do you want Splunk to start with every time it opens? Defaults to `--accept-license --no-prompt`, without both of these Splunk will fail to start automatically as it will be waiting for user input. 

`ADMIN_PASSWORD` 

Sets the default "admin" user account password. Defaults to `changeme2019`. You can change this through the web interface once the container is running. 

# Ports

`8000`

HTTP Splunk web interface. Log in with the username `admin` and the value of `ADMIN_PASSWORD`, which defaults to `changeme2019`. 

`9997`

SplunkTCP data stream, for receiving Splunk indexed data from Splunk Forwarders.

`8089`

HTTPS management API, if you require external API access such as for Deployment Server functionality. 

`8088`

Splunk HTTP Event Collector default port, for receiving Splunk HEC events (such as those sent by Splunk Stream).

`514`

Default Syslog port, if you decide to syslog directly to Splunk rather than the preferred method of monitoring files written by syslog-ng or similar. 

# Volumes

`/splunkdata`

Contains Splunk's indexed data. This is configured in Splunk using the SPLUNK_DB directive in splunk-launch.conf, as written in the gosplunk.sh script.

`/opt/splunk/etc/apps`

Contains Splunk's apps and most customisations made in the GUI.  

# How to reset trial license

* Delete all default indexes from disk
* Delete all default apps from volumes
* Delete your docker image and redownload it. 

For unRAID users you can swap between `:latest` and (`:<version>` such as `:8.0.2`) branches to force a redownload of the base image. Every version from 8.0.0 has a corresponding version available by directly hard-coding a branch. 

You probably don't have to do all these things, but I've found it works consistently. 

# Known Issues

`Sometimes unable to run apps that contain binary modular inputs (like Splunk_TA_Stream) when my $SPLUNK_HOME/etc/apps directory is a volume. Executable shell scripts still work though.`

This is due to the use of the `SYS_RAWIO` capability that is natively disallowed by Docker as a security measure. To get around this, you can run the container in "privileged mode", `--privileged` or there's a checkbox in your unRAID update container screen. The alternative would be only volumising the /local subdirectories of your apps.
