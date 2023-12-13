#!/usr/bin/env bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=master
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

backdrop_download
pushd "$WEB_ROOT/web" >> /dev/null
  BACKDROP_LANG_VER=$( [ "$CMS_VERSION" = "1.x" ] && _drupalx_version x.y-1 || _drupalx_version x.y )
  backdrop_po_download "${CIVICRM_LOCALES:-de_DE}" "backdropcms-${BACKDROP_LANG_VER}"
popd >> /dev/null

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/web/modules" ] && mkdir -p "$WEB_ROOT/web/modules"
pushd "$WEB_ROOT/web/modules" >> /dev/null

  git_cache_clone civicrm/civicrm-core          -b "$CIVI_VERSION"     civicrm
  git_cache_clone civicrm/civicrm-backdrop      -b "1.x-$CIVI_VERSION" civicrm/backdrop
  git_cache_clone civicrm/civicrm-packages      -b "$CIVI_VERSION"     civicrm/packages
  git_cache_clone civicrm/org.civicoop.civirules              -b "$RULES_VERSION"     civicrm/tools/extensions/org.civicoop.civirules
  git_cache_clone TechToThePeople/civisualize                 -b "master"             civicrm/tools/extensions/civisualize
  git_cache_clone civicrm/org.civicrm.module.cividiscount     -b "$DISC_VERSION"      civicrm/tools/extensions/cividiscount
  git_cache_clone civicrm/org.civicrm.contactlayout           -b "master"             civicrm/tools/extensions/org.civicrm.contactlayout
  api4_download_conditional civicrm                                           civicrm/ext/api4
  extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
  git_set_hooks civicrm-drupal      civicrm/backdrop   "../tools/scripts/git"
  git_set_hooks civicrm-core        civicrm            "tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/packages   "../tools/scripts/git"

popd >> /dev/null
