#!/bin/bash

## download.sh -- Download WordPress and CiviCRM

###############################################################################
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'

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

  git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git                -b "$CIVI_VERSION" civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-core.git                     -b "$CIVI_VERSION" civicrm/civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git                 -b "$CIVI_VERSION" civicrm/civicrm/packages
  api4_download_conditional civicrm/civicrm                                              civicrm/civicrm/ext/api4
  git clone ${CACHE_DIR}/civicrm/civicrm-demo-wp.git                  -b master          civicrm-demo-wp
  git clone ${CACHE_DIR}/civicrm/civivolunteer.git                    -b "$VOL_VERSION"  civicrm/civicrm/tools/extensions/civivolunteer
  git clone ${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git -b "$NG_PRFL_VERSION" civicrm/civicrm/tools/extensions/org.civicrm.angularprofiles
  git clone "${CACHE_DIR}/civicrm/org.civicrm.contactlayout.git"      -b "master"        civicrm/tools/extensions/org.civicrm.contactlayout


  cd civicrm
  extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
  cd -

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
