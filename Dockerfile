# Grab base Alpine
FROM alpine:3.10.0
MAINTAINER atunnecliffe <andrew@atunnecliffe.com>

# Set environment variables
ENV HOME /root
ENV SPLUNK_HOME /opt/splunk
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# ARGS
ARG DOWNLOAD_URL=https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.3.0&product=splunk&filename=splunk-7.3.0-657388c7a488-Linux-x86_64.tgz&wget=true
ARG SPLUNK_CLI_ARGS="--accept-license --no-prompt"
ARG ADMIN_PASSWORD=changeme2019
ARG IS_UNRAID=false

# ENVS based on ARGS (so you can configure either at build time or runtime)
ENV DOWNLOAD_URL $DOWNLOAD_URL
ENV SPLUNK_CLI_ARGS $SPLUNK_CLI_ARGS
ENV ADMIN_PASSWORD $ADMIN_PASSWORD
ENV IS_UNRAID $IS_UNRAID

# Install dependancies 
# wget: for downloading Splunk and dependancies
# tar: for installing Splunk 
# alpine-sdk: provides linkers/builders required to run Splunk 
# ca-certificates: required to securely download modified glibc
# procps: required as Splunk uses ps with non-busybox arguments
RUN apk add --no-cache --virtual wget tar alpine-sdk ca-certificates procps

# Install custom glibc builder compatible with Splunk
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk
RUN apk add glibc-2.29-r0.apk

# Add splunk group and user 
RUN addgroup -S splunk && adduser -S splunk -G splunk -g "Splunk User" -s /bin/bash -D splunk

# Move startup script
WORKDIR /opt/splunk
COPY gosplunk.sh /opt/splunk/gosplunk.sh

# Fix permissions
RUN chown -R splunk:splunk /opt/
RUN chmod +x /opt/splunk/gosplunk.sh

USER splunk

# Set up ports and volumes
VOLUME ["/apps"]
EXPOSE 8000 8089 9997

ENTRYPOINT [ "./gosplunk.sh" ]