#!/bin/sh
REL=`lsb_release -id | head -1 | awk '{print $3}'`
echo "$REL" | awk '{print tolower($0)}'
