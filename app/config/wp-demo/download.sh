#!/bin/bash

## download.sh -- Download WordPress and CiviCRM

###############################################################################

WPCLI_ARGS=
[ -n "$CMS_VERSION" ] && WPCLI_ARGS="$WPCLI_ARGS --version=$CMS_VERSION"

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  "$PRJDIR/bin/wp" core download$WPCLI_ARGS
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
  git clone ${CACHE_DIR}/civicrm/civicrm-demo-wp.git   -b master          civicrm-demo-wp

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
