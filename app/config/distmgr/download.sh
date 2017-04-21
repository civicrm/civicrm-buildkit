#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

git_cache_setup "https://github.com/civicrm/civicrm-upgrade-manager.git"              "$CACHE_DIR/civicrm/civicrm-upgrade-manager.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/civicrm/civicrm-upgrade-manager.git" .
  composer install --no-scripts
popd >> /dev/null
