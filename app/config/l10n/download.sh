#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/l10n.git"           "$CACHE_DIR/civicrm/l10n.git"

echo "[[Download CiviCRM]]"

mkdir "$WEB_ROOT"

git clone ${CACHE_DIR}/civicrm/l10n.git                -b "$CIVI_VERSION"     "$WEB_ROOT/l10n"
git clone ${CACHE_DIR}/civicrm/civicrm-core.git        -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-core"
git clone ${CACHE_DIR}/civicrm/civicrm-drupal.git      -b "7.x-$CIVI_VERSION" "$WEB_ROOT/civicrm-drupal"
git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git      -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-joomla"
git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git   -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-wordpress"
git clone ${CACHE_DIR}/civicrm/civicrm-packages.git    -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-packages"

mkdir "$WEB_ROOT/web"
