#!/usr/bin/env bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

git_cache_setup "https://github.com/civicrm/cxnapp.git"              "$CACHE_DIR/civicrm/cxnapp.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/civicrm/cxnapp.git" .
  composer install --no-scripts
popd >> /dev/null
