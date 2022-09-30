#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}" >> /dev/null
  amp datadir var var/save var/tmp
popd >> /dev/null

pushd "${CMS_ROOT}" >> /dev/null
  env WEB_ROOT="$WEB_ROOT" SITE_TOKEN="$SITE_TOKEN" \
    bash "$SITE_CONFIG_DIR"/config-php.sh > config.inc.php
popd >> /dev/null
