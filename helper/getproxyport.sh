#!/bin/bash
FILE_ENA_PROXY="./enable-proxy"
if [ -e $FILE_ENA_PROXY ]; then
    if [[ "$DOCKER_PROXY_PORT" == "" ]]; then
        echo '8142'
    else
        echo $DOCKER_PROXY_PORT
    fi
fi