#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x-dev
[ -z "$CIVI_VERSION" ] && cvutil_fatal "Must specify a CiviCRM version (--civi-ver X.Y)"
[ "$CIVI_VERSION" == "master" ] && cvutil_fatal "Must specify a CiviCRM version (--civi-ver X.Y)"

composer create-project drupal-composer/drupal-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/{devel,libraries}

  ## NOTE: No support for CIVI_VERSION
  ## NOTE: pear/log has a silly requirement for exactly 1.0.0
  composer require roundearth/civicrm-composer-plugin civicrm/civicrm-setup:'dev-master as 0.2.1' civicrm/civicrm-{core,drupal-8}:~${CIVI_VERSION}.0 pear/pear_exception:'1.0.1 as 1.0.0'
  #composer require roundearth/civicrm-composer-plugin civicrm/civicrm-setup:'dev-master as 0.2.1' civicrm/civicrm-core:5.14.2 civicrm/civicrm-drupal-8:5.14.2
  #composer require roundearth/civicrm-composer-plugin civicrm/civicrm-setup:'dev-master as 0.2.1' civicrm/civicrm-drupal-8
  #composer require roundearth/civicrm-composer-plugin civicrm/civicrm-setup:dev-master civicrm/civicrm-drupal-8
popd >> /dev/null
