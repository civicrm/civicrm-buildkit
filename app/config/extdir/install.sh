#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Initial build
pushd "$WEB_ROOT"
  echo "$CMS_URL" > .extdir-url
  ./extdir.sh make
popd
