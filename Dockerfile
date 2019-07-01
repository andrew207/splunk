# Grab base Phusion
FROM phusion/baseimage:0.11
MAINTAINER atunnecliffe <andrew@atunnecliffe.com>

# Make Phusion work as nonroot for OpenShift compatibility
RUN mkdir -p /tmp/my_init.d
COPY setup.sh /tmp/my_init.d/setup.sh
RUN chmod +x /tmp/my_init.d/setup.sh
RUN /tmp/my_init.d/setup.sh

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
ARG DOWNLOAD_URL=https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.3.0&product=splunk&filename=splunk-7.3.0-657388c7a488-linux-2.6-amd64.deb&wget=true
ARG SPLUNK_CLI_ARGS="--accept-license --no-prompt"
ARG ADMIN_PASSWORD=changeme2019
ARG IS_UNRAID=false

# ENVS based on ARGS (so you can configure either at build time or runtime)
ENV DOWNLOAD_URL $DOWNLOAD_URL
ENV SPLUNK_CLI_ARGS $SPLUNK_CLI_ARGS
ENV ADMIN_PASSWORD $ADMIN_PASSWORD
ENV IS_UNRAID $IS_UNRAID

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Install wget
RUN apt-get update -q
RUN apt-get install -y wget

# Set up autostarts
RUN mkdir -p /etc/my_init.d
COPY 50_gosplunk.init /etc/my_init.d/50_gosplunk.init
RUN chmod +x /etc/my_init.d/50_gosplunk.init

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up ports and volumes
EXPOSE 8000 8089 9997
VOLUME ["/opt/splunk/var", "/data", "/apps"]
