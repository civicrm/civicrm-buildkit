#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x-dev

composer create-project drupal-composer/drupal-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/{devel,libraries,userprotect}
  composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-setup:'dev-master as 0.2.99' civicrm/civicrm-{core,packages,drupal-8}:$(civicrm_composer_ver "$CIVI_VERSION") pear/pear_exception:'1.0.1 as 1.0.0' --prefer-source

  ## FIXME: Remove this once patches are merged.
  git scan -N am https://github.com/civicrm/civicrm-core/pull/16328.diff

  ## TODO http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
popd >> /dev/null
