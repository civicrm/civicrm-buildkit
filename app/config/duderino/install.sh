#!/usr/bin/env bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
pushd "$WEB_ROOT"
  amp datadir data
  composer install
  ./bin/duderino install --ignore-web-group
popd
