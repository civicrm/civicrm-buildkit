#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.8.x-dev

mkdir -p "$WEB_ROOT"
composer create-project drupal/legacy-project:"$CMS_VERSION" "$WEB_ROOT/web" --no-interaction

pushd "$WEB_ROOT/web" >> /dev/null
  composer_allow_common_plugins
  composer require drupal/{devel,libraries,userprotect}
  civicrm_download_composer_d8
popd >> /dev/null
