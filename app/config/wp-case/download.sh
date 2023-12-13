#!/usr/bin/env bash

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

  git_cache_clone civicrm/civicrm-wordpress                        -b "$CIVI_VERSION" civicrm
  git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" civicrm/civicrm
  git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" civicrm/civicrm/packages
  api4_download_conditional civicrm/civicrm                                              civicrm/civicrm/ext/api4
  git_cache_clone civicrm/civicrm-demo-wp                          -b master          civicrm-demo-wp

  mkdir -p civicrm/civicrm/ext
  git_cache_clone civicrm/org.civicrm.shoreditch                   -b master civicrm/civicrm/ext/shoreditch
  git_cache_clone civicrm/org.civicrm.styleguide                   -b master civicrm/civicrm/ext/styleguide
  git_cache_clone civicrm/org.civicrm.civicase                     -b master civicrm/civicrm/ext/civicase

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
