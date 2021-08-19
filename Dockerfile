# Grab base Alpine
FROM alpine:3.12.1
LABEL author="atunnecliffe <andrew@atunnecliffe.com>"

# Set environment variables
ENV HOME /root
ENV SPLUNK_HOME /opt/splunk
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# ARGS
ARG DOWNLOAD_TARGET=https://d7wz6hmoaavd0.cloudfront.net/products/splunk/releases/8.2.2/linux/splunk-8.2.2-87344edfcdb4-Linux-x86_64.tgz
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

# Download Splunk and fix permissions
# Configure user nobody to match unRAID's settings
# Splunk expects users to have an entry in /etc/passwd, OpenShift doesn't generate this so we will create one. 
# See additional code in entrypoint script for writing the file.	
RUN FILE=`echo $DOWNLOAD_TARGET | sed -r 's/^.+(splunk-[^-]+).+$/\1/g'` && \
    wget -q -O $SPLUNK_HOME/$FILE.tar.gz $DOWNLOAD_TARGET && \ 
    chgrp -R 0 ${SPLUNK_HOME} && \
    chmod -R g=u ${SPLUNK_HOME} && \
    chmod -R 755 ${SPLUNK_HOME} && \
    chgrp -R 0 /splunkdata && \
    chmod -R g=u /splunkdata && \
    chmod -R 755 /splunkdata && \
    chmod -R g=u /etc/passwd 

# Install dependancies 
# wget: for downloading Splunk and dependancies
# tar: for installing Splunk 
# alpine-sdk: provides linkers/builders required to run Splunk 
# ca-certificates: required to securely download modified glibc
# procps: required as Splunk uses ps with non-busybox arguments
# tzdata: required to set timezone
RUN apk add --no-cache --virtual wget tar alpine-sdk ca-certificates procps tzdata

# Install custom glibc builder compatible with Splunk
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.33-r0/glibc-2.33-r0.apk && \
    apk add glibc-2.33-r0.apk && \
    rm -f glicx-2.33-r0.apk

# Set up ports and volumes
VOLUME ["/apps", "${SPLUNK_HOME}", "/splunkdata"]
EXPOSE 8000 8089 9997 8088 514
 
# Startup
WORKDIR ${SPLUNK_HOME}
ENTRYPOINT [ "./gosplunk.sh" ]
