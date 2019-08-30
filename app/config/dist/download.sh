#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

mkdir "$WEB_ROOT"

git clone ${CACHE_DIR}/civicrm/civicrm-core.git        -b "$CIVI_VERSION"     "$WEB_ROOT/src"
git clone ${CACHE_DIR}/civicrm/civicrm-backdrop.git    -b "1.x-$CIVI_VERSION" "$WEB_ROOT/src/backdrop"
git clone ${CACHE_DIR}/civicrm/civicrm-drupal.git      -b "7.x-$CIVI_VERSION" "$WEB_ROOT/src/drupal"
git clone ${CACHE_DIR}/civicrm/civicrm-drupal-8.git    -b "$CIVI_VERSION"     "$WEB_ROOT/src/drupal-8"
git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git      -b "$CIVI_VERSION"     "$WEB_ROOT/src/joomla"
git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git   -b "$CIVI_VERSION"     "$WEB_ROOT/src/WordPress"
git clone ${CACHE_DIR}/civicrm/civicrm-packages.git    -b "$CIVI_VERSION"     "$WEB_ROOT/src/packages"

## 24hr * 60min/hr * 60sec/min = 86400
http_cache_setup "http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz" "$CACHE_DIR/civicrm/civicrm-l10n-daily.tar.gz" 86400
pushd "$WEB_ROOT/src"
  tar xzf "$CACHE_DIR/civicrm/civicrm-l10n-daily.tar.gz"
popd

mkdir "$WEB_ROOT/web"
