#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=master

backdrop_download

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/web/modules" ] && mkdir -p "$WEB_ROOT/web/modules"
pushd "$WEB_ROOT/web/modules" >> /dev/null

  git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION"     civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-backdrop.git  -b "1.x-$CIVI_VERSION" civicrm/backdrop
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION"     civicrm/packages
  api4_download_conditional civicrm                                           civicrm/ext/api4
  git_set_hooks civicrm-drupal      civicrm/backdrop   "../tools/scripts/git"
  git_set_hooks civicrm-core        civicrm            "tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/packages   "../tools/scripts/git"

popd >> /dev/null
