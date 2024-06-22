#!/bin/bash
FILE_ENA_PROXY="./enable-proxy"
if [ -e $FILE_ENA_PROXY ]; then
    if [[ "$DOCKER_PROXY_IP" == "" ]]; then
        echo `ip address | grep enp | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1`
    else
        echo $DOCKER_PROXY_IP
    fi
fi