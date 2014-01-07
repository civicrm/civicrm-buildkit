#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

pushd "$WEB_ROOT" >> /dev/null
  [ -d .installation.bak ] && mv .installation.bak installation
  [ -f configuration.php ] && rm -f configuration.php
popd >> /dev/null

