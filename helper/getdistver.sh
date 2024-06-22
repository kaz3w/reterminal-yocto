#!/bin/sh
VER=`lsb_release -r | grep -Eo '[0-9]+\.[0-9]+'`
echo "$VER"