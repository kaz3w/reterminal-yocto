#!/bin/sh
ip address | grep enp | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
