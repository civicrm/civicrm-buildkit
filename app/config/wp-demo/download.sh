#!/usr/bin/env bash

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

  git_cache_clone civicrm/civicrm-wordpress                        -b "$CIVI_VERSION" civicrm
  git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" civicrm/civicrm
  git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" civicrm/civicrm/packages
  api4_download_conditional civicrm/civicrm                                              civicrm/civicrm/ext/api4
  git_cache_clone civicrm/civicrm-demo-wp                          -b master          civicrm-demo-wp
  git clone ${CACHE_DIR}/civicrm/civivolunteer.git                    -b "$VOL_VERSION"  civicrm/civicrm/tools/extensions/civivolunteer
  git clone ${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git -b "$NG_PRFL_VERSION" civicrm/civicrm/tools/extensions/org.civicrm.angularprofiles
  git_cache_clone civicrm/org.civicoop.civirules                   -b master          civicrm/civicrm/tools/extensions/org.civicoop.civirules
  git_cache_clone TechToThePeople/civisualize                      -b master          civicrm/civicrm/tools/extensions/civisualize
  git_cache_clone civicrm/org.civicrm.module.cividiscount          -b master          civicrm/civicrm/tools/extensions/cividiscount
  git_cache_clone civicrm/org.civicrm.contactlayout                -b master          civicrm/civicrm/tools/extensions/org.civicrm.contactlayout

#  cd civicrm
  civicrm_l10n_setup civicrm/civicrm
#  cd -

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
