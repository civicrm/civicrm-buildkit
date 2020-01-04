#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x

drupal_download

pushd "$WEB_ROOT/web"
  drush dl -y libraries-1.0 views-3.7 devel
popd
