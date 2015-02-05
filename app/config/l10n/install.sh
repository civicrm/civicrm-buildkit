#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
# cvutil_mkdir "$WEB_ROOT/out" "$WEB_ROOT/out/gen" "$WEB_ROOT/out/tmp" "$WEB_ROOT/out/tar" "$WEB_ROOT/out/config"
