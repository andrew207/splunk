# Splunk 
This is a Dockerfile for Splunk, currently running version 7.3.1.1 - https://www.splunk.com

It is based on Alpine Linux and supports OpenShift and unRAID.

It is designed to deploy Splunk Enterprise quickly and easily. The web interface is exposed on port HTTP/8000, data ingest on TCP/9997, and API on HTTPS/8089. 

If you run the Dockerfile with no arguments you will get a single instance of Splunk 7.3.1.1 with the user admin:changeme2019. 

Compatible with Splunk 7.1.0 and newer. 

# Usage
Single instance with no persistence 

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 --name splunk atunnecliffe/splunk`

Single instance with indexed data and config/app persistence in unRAID

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 -v '/mnt/user/appdata/splunk/var/lib/splunk':'/opt/splunk/lib/splunk':'rw' -v '/mnt/user/appdata/splunk/etc':'/opt/splunk/etc':'rw' --name splunk atunnecliffe/splunk`

Install an older version (7.2.6) and change admin password

`docker run -d -p 8000:8000 -p 8089:8089 -p 9997:9997 -e ADMIN_PASSWORD="mynewpassword" -e DOWNLOAD_URL="https://www.splunk.com/page/download_track?file=7.2.6/linux/splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=7.2.6&product=splunk&typed=release" -p 8000:8000 --name splunk atunnecliffe/splunk`

# Arguments
`DOWNLOAD_URL` 

is a direct link to download the .DEB file of your desired release obtained from the "download via WGET" button on the website. This Dockerfile is compatible with versions newer than 7.1.1. Currently defaults to version 7.2.6. 

`SPLUNK_CLI_ARGS` 

What args do you want Splunk to start with every time it opens? Defaults to `--accept-license --no-prompt`, without both of these Splunk will fail to start automatically as it will be waiting for user input. 

`ADMIN_PASSWORD` 

Sets the default "admin" user account password. Defaults to `changeme2019`. You can change this through the web interface once the container is running. 

# Volumes

`/apps`

The contents of this directory is forcefully copied into /opt/splunk/etc/apps on container startup. Use this volume to place all your the apps you want pre-installed. 
