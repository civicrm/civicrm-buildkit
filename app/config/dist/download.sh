#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION" "$WEB_ROOT"
git clone ${CACHE_DIR}/civicrm/civicrm-drupal.git    -b "7.x-$CIVI_VERSION" "$WEB_ROOT/drupal"
git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git    -b "$CIVI_VERSION" "$WEB_ROOT/joomla"
git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git -b "$CIVI_VERSION" "$WEB_ROOT/WordPress"
git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION" "$WEB_ROOT/packages"
