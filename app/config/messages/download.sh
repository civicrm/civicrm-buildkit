#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download civicrm-community-messages]]"

git_cache_setup "https://github.com/civicrm/civicrm-community-messages.git"              "$CACHE_DIR/civicrm/civicrm-community-messages.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/civicrm/civicrm-community-messages.git" .
  composer install --no-scripts
popd >> /dev/null
