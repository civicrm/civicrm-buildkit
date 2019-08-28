#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

pushd "$WEB_ROOT/web" >> /dev/null
  [ -d .installation.bak ] && mv .installation.bak installation
  [ -d .git.bak ]          && mv .git.bak .git
  [ -f configuration.php ] && rm -f configuration.php
popd >> /dev/null

