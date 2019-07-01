#!/bin/bash
set -e
source /tmp/buildconfig

header "Finalizing..."

if [[ -e /usr/local/rvm ]]; then
    run /usr/local/rvm/bin/rvm cleanup all
fi

run apt-get autoclean 
run apt-get remove -y autoconf automake
run apt-get autoremove
run apt-get clean
run rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
run rm -rf /var/lib/apt 
run rm -rf /image_build