# Grab base Ubuntu
FROM ubuntu:24.04
LABEL author="atunnecliffe <andrew@atunnecliffe.com>"

# Set environment variables
ENV HOME /root
ENV SPLUNK_HOME /opt/splunk
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# ARGS
ARG DOWNLOAD_TARGET=https://download.splunk.com/products/splunk/releases/9.2.2/linux/splunk-9.2.2-d76edf6f0a15-Linux-x86_64.tgz
ARG SPLUNK_CLI_ARGS="--accept-license --no-prompt"
ARG ADMIN_PASSWORD=changeme2019
ARG TZ=Etc/UTC

# ENVS based on ARGS (so you can configure either at build time or runtime)
ENV DOWNLOAD_TARGET $DOWNLOAD_TARGET
ENV SPLUNK_CLI_ARGS $SPLUNK_CLI_ARGS
ENV ADMIN_PASSWORD $ADMIN_PASSWORD
ENV TZ=$TZ

# Add Splunk to env
ENV PATH=${SPLUNK_HOME}/bin:${PATH} HOME=$SPLUNK_HOME

# Add indexed data dir
RUN mkdir -p /splunkdata

# Prepare startup script
WORKDIR ${SPLUNK_HOME}
COPY gosplunk.sh ./gosplunk.sh
RUN chmod +x ./gosplunk.sh

# Download requirements
RUN apt-get update && \
    apt-get install -y wget 

# Download Splunk and fix permissions
# Configure user nobody to match unRAID's settings
# Splunk expects users to have an entry in /etc/passwd, OpenShift doesn't generate this so we will create one. 
# See additional code in entrypoint script for writing the file.	
RUN chgrp -R 0 ${SPLUNK_HOME} && \
    chmod -R g=u ${SPLUNK_HOME} && \
    chmod -R 755 ${SPLUNK_HOME} && \
    chgrp -R 0 /splunkdata && \
    chmod -R g=u /splunkdata && \
    chmod -R 755 /splunkdata && \
    chmod -R g=u /etc/passwd 

# Set up ports and volumes
VOLUME ["/apps", "${SPLUNK_HOME}", "/splunkdata"]
EXPOSE 8000 8089 9997 8088 514
 
# Startup
WORKDIR ${SPLUNK_HOME}
ENTRYPOINT [ "./gosplunk.sh" ]
