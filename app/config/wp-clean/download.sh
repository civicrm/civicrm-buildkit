#!/usr/bin/env bash

## download.sh -- Download WordPress and CiviCRM

###############################################################################
[ -z "$CMS_VERSION" ] && CMS_VERSION=latest

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT" "$WEB_ROOT/web"
pushd "$WEB_ROOT/web" >> /dev/null
  "$PRJDIR/bin/wp" core download --version=$CMS_VERSION
  if [ ! -e "wp-cli.yml" ]; then
    cp -a "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/web/wp-content/plugins" ] && mkdir -p "$WEB_ROOT/web/wp-content/plugins"
pushd "$WEB_ROOT/web/wp-content/plugins" >> /dev/null

  git_cache_clone civicrm/civicrm-wordpress                        -b "$CIVI_VERSION" civicrm
  git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" civicrm/civicrm
  git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" civicrm/civicrm/packages

  cd civicrm
  extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
  cd -

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
