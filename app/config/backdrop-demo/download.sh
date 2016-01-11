#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -n "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=master

echo "[[Download Backdrop]]"
git clone "$CACHE_DIR/backdrop/backdrop.git" "$WEB_ROOT"

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/moduless" ] && mkdir -p "$WEB_ROOT/modules"
pushd $WEB_ROOT/modules >> /dev/null

  git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION"     civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-backdrop.git  -b "1.x-$CIVI_VERSION" civicrm/backdrop
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION"     civicrm/packages

  git_set_hooks civicrm-drupal      civicrm/backdrop   "../tools/scripts/git"
  git_set_hooks civicrm-core        civicrm            "tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/packages   "../tools/scripts/git"

popd >> /dev/null
