#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Download CiviCRM]]"

mkdir "$WEB_ROOT"

git clone ${CACHE_DIR}/civicrm/civicrm-core.git        -b "$CIVI_VERSION"     "$WEB_ROOT/src"
git clone ${CACHE_DIR}/civicrm/civicrm-drupal.git      -b "7.x-$CIVI_VERSION" "$WEB_ROOT/src/drupal"
git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git      -b "$CIVI_VERSION"     "$WEB_ROOT/src/joomla"
git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git   -b "$CIVI_VERSION"     "$WEB_ROOT/src/WordPress"
git clone ${CACHE_DIR}/civicrm/civicrm-packages.git    -b "$CIVI_VERSION"     "$WEB_ROOT/src/packages"
svn_cache_clone "$CACHE_DIR/civicrm/l10n-trunk.svn"                           "$WEB_ROOT/src/l10n"

mkdir "$WEB_ROOT/web"
