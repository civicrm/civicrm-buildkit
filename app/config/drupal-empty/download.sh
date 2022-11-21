#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7

drupal_download

pushd "$WEB_ROOT/web"
  drush dl -y libraries-1.0 views-3.7 devel-1.x
  drupal7_po_download "${CIVICRM_LOCALES:-de_DE}" drupal-7.x views-7.x-3.x devel-7.x-1.x
popd
