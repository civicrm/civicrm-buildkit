#!/bin/bash

## download.sh -- Download WordPress and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=3.7

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  "$PRJDIR/bin/wp" core download --version="$CMS_VERSION"
  if [ ! -e "wp-cli.yml" ]; then
    ln -s "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/wp-content/plugins" ] && mkdir -p "$WEB_ROOT/wp-content/plugins"
pushd $WEB_ROOT/wp-content/plugins >> /dev/null

  git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git -b "$CIVI_VERSION" civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION" civicrm/civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION" civicrm/civicrm/packages

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
