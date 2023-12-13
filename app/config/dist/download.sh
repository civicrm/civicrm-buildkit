#!/usr/bin/env bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

mkdir "$WEB_ROOT"

git_cache_clone civicrm/civicrm-core                -b "$CIVI_VERSION"     "$WEB_ROOT/src"
git_cache_clone civicrm/civicrm-backdrop            -b "1.x-$CIVI_VERSION" "$WEB_ROOT/src/backdrop"
git_cache_clone civicrm/civicrm-drupal              -b "7.x-$CIVI_VERSION" "$WEB_ROOT/src/drupal"
git_cache_clone civicrm/civicrm-drupal-8            -b "$CIVI_VERSION"     "$WEB_ROOT/src/drupal-8"
git_cache_clone civicrm/civicrm-joomla              -b "$CIVI_VERSION"     "$WEB_ROOT/src/joomla"
git_cache_clone civicrm/civicrm-wordpress           -b "$CIVI_VERSION"     "$WEB_ROOT/src/WordPress"
git_cache_clone civicrm/civicrm-packages            -b "$CIVI_VERSION"     "$WEB_ROOT/src/packages"

## 24hr * 60min/hr * 60sec/min = 86400
http_cache_setup "http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz" "$CACHE_DIR/civicrm/civicrm-l10n-daily.tar.gz" 86400
pushd "$WEB_ROOT/src"
  tar xzf "$CACHE_DIR/civicrm/civicrm-l10n-daily.tar.gz"
popd

mkdir "$WEB_ROOT/web"
