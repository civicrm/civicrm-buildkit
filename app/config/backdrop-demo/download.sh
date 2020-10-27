#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=master
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

backdrop_download

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/web/modules" ] && mkdir -p "$WEB_ROOT/web/modules"
pushd "$WEB_ROOT/web/modules" >> /dev/null

  git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION"     civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-backdrop.git  -b "1.x-$CIVI_VERSION" civicrm/backdrop
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION"     civicrm/packages
  git clone "${CACHE_DIR}/civicrm/civivolunteer.git"                       -b "$VOL_VERSION"       civicrm/tools/extensions/civivolunteer
  git clone "${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git"    -b "$NG_PRFL_VERSION"   civicrm/tools/extensions/org.civicrm.angularprofiles
  git clone "${CACHE_DIR}/civicrm/org.civicoop.civirules.git"              -b "$RULES_VERSION"     civicrm/tools/extensions/org.civicoop.civirules
  git clone "${CACHE_DIR}/TechToThePeople/civisualize.git"                 -b "master"             civicrm/tools/extensions/civisualize
  git clone "${CACHE_DIR}/civicrm/org.civicrm.module.cividiscount.git"     -b "$DISC_VERSION"      civicrm/tools/extensions/cividiscount
  git clone "${CACHE_DIR}/civicrm/org.civicrm.contactlayout.git"           -b "master"             civicrm/tools/extensions/org.civicrm.contactlayout
  api4_download_conditional civicrm                                           civicrm/ext/api4
  extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
  git_set_hooks civicrm-drupal      civicrm/backdrop   "../tools/scripts/git"
  git_set_hooks civicrm-core        civicrm            "tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/packages   "../tools/scripts/git"

popd >> /dev/null
