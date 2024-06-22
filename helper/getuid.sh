#!/bin/sh
id `whoami` | grep -Eo '[0-9]+' | head -1