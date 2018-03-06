#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=8.4.x

[ -d "$WEB_ROOT.drushtmp" ] && rm -rf "$WEB_ROOT.drushtmp"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT.drushtmp" --drupal-project-rename
mv "$WEB_ROOT.drushtmp/drupal" "$WEB_ROOT"
[ -d "$WEB_ROOT.drushtmp" ] && rm -rf "$WEB_ROOT.drushtmp"

pushd "$WEB_ROOT"
  drush8 dl -y devel-1 libraries
popd
