# Grab base Phusion
FROM phusion/baseimage:0.11
MAINTAINER atunnecliffe <andrew@atunnecliffe.com>

# Set environment variables
ENV HOME /root
ENV SPLUNK_HOME /opt/splunk
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# Run baseimage init
CMD ["/sbin/my_init"]

# ARGS
ARG DOWNLOAD_URL=https://www.splunk.com/page/download_track?file=7.2.6/linux/splunk-7.2.6-c0bf0f679ce9-linux-2.6-amd64.deb&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=7.2.6&product=splunk&typed=release
ARG SPLUNK_CLI_ARGS="--accept-license --no-prompt"
ARG ADMIN_PASSWORD=changeme2019

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Install wget
RUN apt-get update -q
RUN apt-get install -y wget

# Download and install Splunk Enterprise
RUN wget -O splunkenterprise.deb ${DOWNLOAD_URL}
RUN dpkg -i /splunkenterprise.deb

# Fix "unusable filesystem" when Splunkd tries to create files
RUN printf "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\n" >> $SPLUNK_HOME/etc/splunk-launch.conf

# Configure default user
RUN echo "[user_info]\n\
USERNAME = admin\n\
PASSWORD = ${ADMIN_PASSWORD}" > $SPLUNK_HOME/etc/system/local/user-seed.conf

# Install apps and configure startup
RUN echo "#!/bin/sh\n\
yes | cp -rf /apps/* /opt/splunk/etc/apps\n\
/opt/splunk/bin/splunk start ${SPLUNK_CLI_ARGS}\n\
exit 0" > /etc/rc.local
RUN chmod +x /etc/rc.local

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up ports and volumes
EXPOSE 8000 8089 9997
VOLUME ["/opt/splunk/var", "/data", "/apps"]
