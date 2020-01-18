#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  drush8 dl -y devel-1 libraries userprotect
  composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-setup:'dev-master as 0.2.99' civicrm/civicrm-{core,packages,drupal-8}:$(civicrm_composer_ver "$CIVI_VERSION") --prefer-source

  ## FIXME: Remove this once patches are merged.
  git scan -N am https://github.com/civicrm/civicrm-core/pull/16328.diff

  ## TODO http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
popd
