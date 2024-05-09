#!/usr/bin/env bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7

drupal_download

pushd "$WEB_ROOT/web"
  drush dl -y libraries-1.0 views-3.7
  drupal7_po_download "${CIVICRM_LOCALES:-de_DE}" drupal-7.x views-7.x-3.x

  pushd sites/all/modules
    git_cache_clone "civicrm/civicrm-core"                                -b "$CIVI_VERSION"      civicrm
    git_cache_clone "civicrm/civicrm-drupal"                              -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git_cache_clone "civicrm/civicrm-packages"                            -b "$CIVI_VERSION"      civicrm/packages
    api4_download_conditional civicrm                                                                civicrm/ext/api4

    civicrm_l10n_setup civicrm

    civibuild_apply_user_extras
    pushd civicrm
      composer install
    popd
  popd

popd
