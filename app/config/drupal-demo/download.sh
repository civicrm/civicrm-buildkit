#!/usr/bin/env bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

drupal_download

pushd "$WEB_ROOT/web"
  drush8 dl -y libraries-1.x redirect-1.x webform-4.x options_element-1.x webform_civicrm-4.x views-3.x login_destination-1.x userprotect-1.x
  drupal7_po_download "${CIVICRM_LOCALES:-de_DE}" drupal-7.x webform-7.x-4.x webform_civicrm-7.x-4.x views-7.x-3.x login_destination-7.x-1.x userprotect-7.x-1.x

  pushd sites/all/modules
    git_cache_clone "civicrm/civicrm-core"                                -b "$CIVI_VERSION"      civicrm
    git_cache_clone "civicrm/civicrm-drupal"                              -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git_cache_clone "civicrm/civicrm-packages"                            -b "$CIVI_VERSION"      civicrm/packages
    api4_download_conditional civicrm                                                                civicrm/ext/api4
    git_cache_clone "civicrm/org.civicoop.civirules"                      -b "$RULES_VERSION"     civicrm/tools/extensions/org.civicoop.civirules
    git_cache_clone "TechToThePeople/civisualize"                         -b "master"             civicrm/tools/extensions/civisualize
    git_cache_clone "civicrm/org.civicrm.module.cividiscount"             -b "$DISC_VERSION"      civicrm/tools/extensions/cividiscount
    git_cache_clone "civicrm/org.civicrm.contactlayout"                   -b "master"             civicrm/tools/extensions/org.civicrm.contactlayout
    civicrm_l10n_setup civicrm

    civibuild_apply_user_extras
    CIVI_CORE="$PWD/civicrm" civicrm_composer_install
  popd

popd
