#!/usr/bin/env bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download civicrm-community-messages]]"

git_cache_setup "https://lab.civicrm.org/infra/community-messages.git"  "$CACHE_DIR/civicrm/civicrm-community-messages.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/civicrm/civicrm-community-messages.git" .
  composer install --no-scripts
popd >> /dev/null
