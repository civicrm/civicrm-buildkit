#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION='^9'

mkdir "$WEB_ROOT"
composer create-project drupal/recommended-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer_allow_common_plugins
  composer require drupal/devel
  drupal8_po_download "${CIVICRM_LOCALES:-de_DE}" "drupal-$( _drupalx_version x.y ).x" devel-5.0.x
popd >> /dev/null
