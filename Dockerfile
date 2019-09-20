# Grab base Alpine
FROM alpine:3.10.2
MAINTAINER atunnecliffe <andrew@atunnecliffe.com>

# Set environment variables
ENV HOME /root
ENV SPLUNK_HOME /opt/splunk
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# ARGS
ARG DOWNLOAD_URL=https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.3.1.1&product=splunk&filename=splunk-7.3.1.1-7651b7244cf2-Linux-x86_64.tgz&wget=true
ARG SPLUNK_CLI_ARGS="--accept-license --no-prompt"
ARG ADMIN_PASSWORD=changeme2019

# ENVS based on ARGS (so you can configure either at build time or runtime)
ENV DOWNLOAD_URL $DOWNLOAD_URL
ENV SPLUNK_CLI_ARGS $SPLUNK_CLI_ARGS
ENV ADMIN_PASSWORD $ADMIN_PASSWORD

# Install dependancies 
# wget: for downloading Splunk and dependancies
# tar: for installing Splunk 
# alpine-sdk: provides linkers/builders required to run Splunk 
# ca-certificates: required to securely download modified glibc
# procps: required as Splunk uses ps with non-busybox arguments
RUN apk add --no-cache --virtual wget tar alpine-sdk ca-certificates procps

# Install custom glibc builder compatible with Splunk
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk && \
    apk add glibc-2.29-r0.apk && \
    rm -f glicx-2.29-r0.apk
    
# Move startup script
RUN mkdir -p $SPLUNK_HOME
WORKDIR $SPLUNK_HOME
COPY gosplunk.sh $SPLUNK_HOME/gosplunk.sh
RUN chmod +x $SPLUNK_HOME/gosplunk.sh

# Add Splunk to env
ENV PATH=${SPLUNK_HOME}/bin:${PATH} HOME=$SPLUNK_HOME

# Prepare startup script
WORKDIR ${SPLUNK_HOME}
COPY gosplunk.sh ./gosplunk.sh
RUN chmod +x ./gosplunk.sh

# Add Splunk to env
ENV PATH=${SPLUNK_HOME}/bin:${PATH} HOME=${SPLUNK_HOME}

# Set up ports and volumes
VOLUME ["/apps", "${SPLUNK_HOME}/var", "${SPLUNK_HOME}/etc/apps"]
EXPOSE 8000 8089 9997

# Download Splunk and fix permissions
# Configure user nobody to match unRAID's settings
# Splunk expects users to have an entry in /etc/passwd, OpenShift doesn't generate this so we will create one. 
# See additional code in entrypoint script for writing the file.	
RUN FILE=`echo $DOWNLOAD_URL | sed -r 's/^.+(splunk-[^-]+).+$/\1/g'` && \
    wget -q -O $SPLUNK_HOME/$FILE.tar.gz $DOWNLOAD_URL && \ 
	chgrp -R 0 ${SPLUNK_HOME} && \
    chmod -R g=u ${SPLUNK_HOME} && \
    chmod -R g=u /etc/passwd 
 
# Startup and change our user
ENTRYPOINT [ "./gosplunk.sh" ]
USER 10001
